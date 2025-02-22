# == Schema Information
#
# Table name: dossier_operation_logs
#
#  id                  :bigint           not null, primary key
#  automatic_operation :boolean          default(FALSE), not null
#  digest              :text
#  executed_at         :datetime
#  keep_until          :datetime
#  operation           :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  bill_signature_id   :bigint
#  dossier_id          :bigint
#
class DossierOperationLog < ApplicationRecord
  enum operation: {
    changer_groupe_instructeur: 'changer_groupe_instructeur',
    passer_en_instruction: 'passer_en_instruction',
    repasser_en_construction: 'repasser_en_construction',
    repasser_en_instruction: 'repasser_en_instruction',
    accepter: 'accepter',
    refuser: 'refuser',
    classer_sans_suite: 'classer_sans_suite',
    supprimer: 'supprimer',
    restaurer: 'restaurer',
    modifier_annotation: 'modifier_annotation',
    demander_un_avis: 'demander_un_avis',
    archiver: 'archiver',
    desarchiver: 'desarchiver'
  }

  has_one_attached :serialized

  belongs_to :dossier, optional: true
  belongs_to :bill_signature, optional: true

  scope :not_deletion, -> { where.not(operation: operations.fetch(:supprimer)) }
  scope :brouillon_expired, -> { where(dossier: Dossier.brouillon_expired).not_deletion }
  scope :en_construction_expired, -> { where(dossier: Dossier.en_construction_expired).not_deletion }
  scope :termine_expired, -> { where(dossier: Dossier.termine_expired).not_deletion }

  def self.create_and_serialize(params)
    dossier = params.fetch(:dossier)

    duree_conservation_dossiers = dossier.procedure.duree_conservation_dossiers_dans_ds
    keep_until = if duree_conservation_dossiers.present?
      if dossier.en_instruction_at
        dossier.en_instruction_at + duree_conservation_dossiers.months
      else
        dossier.created_at + duree_conservation_dossiers.months
      end
    end

    operation_log = new(operation: params.fetch(:operation),
      dossier_id: dossier.id,
      keep_until: keep_until,
      executed_at: Time.zone.now,
      automatic_operation: !!params[:automatic_operation])

    serialized = {
      operation: operation_log.operation,
      dossier_id: operation_log.dossier_id,
      author: self.serialize_author(params[:author]),
      subject: self.serialize_subject(params[:subject], operation_log.operation),
      automatic_operation: operation_log.automatic_operation?,
      executed_at: operation_log.executed_at.iso8601
    }.compact.to_json

    operation_log.digest = Digest::SHA256.hexdigest(serialized)

    operation_log.serialized.attach(
      io: StringIO.new(serialized),
      filename: "operation-#{operation_log.digest}.json",
      content_type: 'application/json',
      # we don't want to run virus scanner on this file
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )

    operation_log.save!
  end

  def self.serialize_author(author)
    if author.nil?
      nil
    else
      {
        id: serialize_author_id(author),
        email: author.email
      }.as_json
    end
  end

  def self.serialize_author_id(object)
    case object
    when User
      "Usager##{object.id}"
    when Instructeur
      "Instructeur##{object.id}"
    when Administrateur
      "Administrateur##{object.id}"
    when SuperAdmin
      "Manager##{object.id}"
    else
      nil
    end
  end

  def self.serialize_subject(subject, operation = nil)
    if subject.nil?
      nil
    elsif operation == operations.fetch(:supprimer)
      {
        date_de_depot: subject.depose_at,
        date_de_mise_en_instruction: subject.en_instruction_at,
        date_de_decision: subject.processed_at
      }.as_json
    else
      case subject
      when Dossier
        SerializerService.dossier(subject)
      when Champ
        SerializerService.champ(subject)
      when Avis
        SerializerService.avis(subject)
      end
    end
  end
end
