class TaskController < ApplicationController
  protect_from_forgery prepend: true, with: :null_session
  layout false

  def perform
    ## REACT TEMP
    if ENV['BACKGROUND_WORKER'] == 'true'
      begin
        job = ActiveJob::Base.deserialize params
        job.perform_now()
      rescue Exception => ex
        Rails.logger.info("Perform ERROR show params: #{params}")
        Rails.logger.info('Perform ERROR :' + ex.message)
        ex.backtrace.each do |line|
          Rails.logger.info('Perform ERROR :' + line)
        end
      end
    end

    respond_to do |format|
      msg = {status: 'ok'}
      format.html {render(text: 'good')}
      format.json {render json: msg}
    end
  end

  def pulling_events_by_type_successful
    if ENV['BACKGROUND_WORKER'] == 'true'
      begin
        end_date =  DateTime.now
        PullingEventsByType.perform_later(end_date.utc.to_i, 'successful', 'nil')
      rescue Exception => ex
        Rails.logger.info ex.message
      end
    end

    respond_to do |format|
      msg = {status: 'ok'}
      format.html {render(text: 'good')}
      format.json {render json: msg}
    end
  end

  def pulling_events_by_type_transfer
    if ENV['BACKGROUND_WORKER'] == 'true'
      begin
        end_date = DateTime.now
        PullingEventsByType.perform_later(end_date.utc.to_i, 'transfer', 'nil')
      rescue Exception => ex
        Rails.logger.info ex.message
      end
    end

    respond_to do |format|
      msg = {status: 'ok'}
      format.html {render(text: 'good')}
      format.json {render json: msg}
    end
  end

  # def pulling_events_by_type_created
  #   # if ENV['BACKGROUND_WORKER'] == 'true' && ENV['BACKGROUND_WORKER_NUMBER'] == 'second'
  #   if ENV['BACKGROUND_WORKER'] == 'true' && ENV['BACKGROUND_WORKER_NUMBER'] == 'third'
  #     begin
  #       end_date = DateTime.now
  #       start_date = end_date - (2).minutes
  #       PullingEventCreatedForUpdateListingsJob.perform_later(start_date.utc.to_i, end_date.utc.to_i, 'created')
  #     rescue Exception => ex
  #       Rails.logger.info ex.message
  #     end
  #   end
  #
  #   respond_to do |format|
  #     msg = {status: 'ok'}
  #     format.html {render(text: 'good')}
  #     format.json {render json: msg}
  #   end
  # end
  #
  # def pulling_events_by_type_cancelled
  #   if ENV['BACKGROUND_WORKER'] == 'true' && ENV['BACKGROUND_WORKER_NUMBER'] == 'second'
  #     begin
  #       end_date = DateTime.now
  #       start_date = end_date - (1.5).minutes
  #       PullingEventCreatedForUpdateListingsJob.perform_later(start_date.utc.to_i, end_date.utc.to_i, 'cancelled')
  #     rescue Exception => ex
  #       Rails.logger.info ex.message
  #     end
  #   end
  #
  #   respond_to do |format|
  #     msg = {status: 'ok'}
  #     format.html {render(text: 'good')}
  #     format.json {render json: msg}
  #   end
  # end

  def delete_listings_which_expiration
    if ENV['BACKGROUND_WORKER'] == 'true'
      begin
        DeleteListingsWhichExpirationJob.perform_now()
      rescue Exception => ex
        Rails.logger.info ex.message
      end
    end

    respond_to do |format|
      msg = {status: 'ok'}
      format.html {render(text: 'good')}
      format.json {render json: msg}
    end
  end

  def check_updating_users
    if ENV['BACKGROUND_WORKER'] == 'true'
      begin
        CheckUpdatingUsersJob.perform_now()
      rescue Exception => ex
        Rails.logger.info ex.message
      end
    end

    respond_to do |format|
      msg = {status: 'ok'}
      format.html {render(text: 'good')}
      format.json {render json: msg}
    end
  end
  
  def get_gas_fee
    begin
      PullingGasFeeJob.perform_now()
    rescue Exception => ex
      Rails.logger.info ex.messagex
    end
    
    respond_to do |format|
      msg = {status: 'ok'}
      format.html {render(text: 'good')}
      format.json {render json: msg}
    end
  end

  def health_check_workers
    if ENV['BACKGROUND_WORKER'] == 'true'
      begin
        HealthcheckWorkersJob.perform_now()
      rescue Exception => ex
        Rails.logger.info ex.message
      end
    end

    respond_to do |format|
      msg = {status: 'ok'}
      format.html {render(text: 'good')}
      format.json {render json: msg}
    end
  end

  def add_listings_from_stream_api
    if ENV['BACKGROUND_WORKER'] == 'true'
      begin
        AddListingsFromStreamApiJob.perform_later(event)
      rescue Exception => ex
        Rails.logger.info ex.message
      end
    end

    respond_to do |format|
      msg = {status: 'ok'}
      format.html {render(text: 'good')}
      format.json {render json: msg}
    end
  end

end
