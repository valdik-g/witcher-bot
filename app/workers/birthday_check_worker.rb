class BirthdayCheckWorker
    include Sidekiq::Worker
  
    def perform()
      BirthdayJob.perform_now()
    end
  end