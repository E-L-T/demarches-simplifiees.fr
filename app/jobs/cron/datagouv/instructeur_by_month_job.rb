class Cron::Datagouv::InstructeurByMonthJob < Cron::CronJob
  include DatagouvCronSchedulableConcern
  self.schedule_expression = "every month at 3:00"
  FILE_NAME = "nb_instructeurs_crees_par_mois"

  def perform(*args)
    GenerateOpenDataCsvService.save_csv_to_tmp(FILE_NAME, data) do |file|
      begin
        APIDatagouv::API.upload(file, :statistics_dataset)
      ensure
        FileUtils.rm(file)
      end
    end
  end

  def data
    Instructeur.where(created_at: 1.month.ago.beginning_of_month..1.month.ago.end_of_month).count
  end
end
