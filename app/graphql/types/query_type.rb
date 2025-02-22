module Types
  class QueryType < Types::BaseObject
    field_class BaseField

    field :demarche, DemarcheType, null: false, description: "Informations concernant une démarche." do
      argument :number, Int, "Numéro de la démarche.", required: true
    end

    field :dossier, DossierType, null: false, description: "Informations sur un dossier d’une démarche." do
      argument :number, Int, "Numéro du dossier.", required: true
    end

    field :groupe_instructeur, GroupeInstructeurWithDossiersType, null: false, description: "Informations sur un groupe instructeur." do
      argument :number, Int, "Numéro du groupe instructeur.", required: true
    end

    field :demarches_publiques, DemarcheDescriptorType.connection_type, null: false, internal: true

    def demarches_publiques
      Procedure.opendata.includes(draft_revision: :procedure, published_revision: :procedure)
    end

    def demarche(number:)
      Procedure.for_api_v2.find(number)
    rescue => e
      raise GraphQL::ExecutionError.new(e.message, extensions: { code: :not_found })
    end

    def dossier(number:)
      if context.internal_use?
        Dossier.state_not_brouillon.for_api_v2.find(number)
      else
        Dossier.visible_by_administration.for_api_v2.find(number)
      end
    rescue => e
      raise GraphQL::ExecutionError.new(e.message, extensions: { code: :not_found })
    end

    def groupe_instructeur(number:)
      GroupeInstructeur.for_api_v2.find(number)
    rescue => e
      raise GraphQL::ExecutionError.new(e.message, extensions: { code: :not_found })
    end

    def self.accessible?(context)
      context[:token] || context[:administrateur_id]
    end
  end
end
