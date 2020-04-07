class SubscriptionsController < ManageCmrController
  include UrsUserEndpoints

  RESULTS_PER_PAGE = 25
  before_action :subscriptions_enabled?
  before_action :add_top_level_breadcrumbs
  before_action :fetch_native_id, only: %i[update destroy]

  def index
    authorize :subscription
    subscription_response = cmr_client.get_subscriptions({'provider_id' => current_user.provider_id}, token)
    if subscription_response.success?
      @subscriptions = subscription_response.body['items'].map do |item|
        subscription = item['umm']
        subscription['ConceptId'] = item['meta']['concept-id']
        subscription
      end
    else
      Rails.logger.error("Error while retrieving subscriptions for #{current_user} in #{current_user.provider_id}; CMR Response: #{subscription_response.clean_inspect}")
      flash[:error] = subscription_response.error_message
      @subscriptions = []
    end
    @subscriptions = Kaminari.paginate_array(@subscriptions, total_count: @subscriptions.count).page(params.fetch('page', 1)).per(RESULTS_PER_PAGE)
  end

  def new
    authorize :subscription
    @subscription = {}
    @subscriber = []

    add_breadcrumb 'New', new_subscription_path
  end

  def show
    authorize :subscription

    concept_id = params.permit(:id)['id']
    subscription_response = cmr_client.get_concept(concept_id, token, {})
    if subscription_response.success?
      @subscription = subscription_response.body
      @subscription['id'] = concept_id
      user = get_subscriber(@subscription['SubscriberId']).fetch(0, {})
      @user = "#{user['first_name']} #{user['last_name']}"
      add_breadcrumb @subscription['id'].to_s
    else
      Rails.logger.info("Could not find subscription: #{subscription_response.clean_inspect}")
      flash[:error] = subscription_response.error_message
      redirect_to subscriptions_path
    end
  end

  def edit
    authorize :subscription

    concept_id = params.permit(:id)['id']
    subscription_response = cmr_client.get_concept(concept_id, token, {})
    if subscription_response.success?
      @subscription = subscription_response.body
      @subscription['id'] = concept_id
      set_previously_selected_subscriber(@subscription['SubscriberId'])
      add_breadcrumb @subscription['id'].to_s, subscription_path(@subscription['id'])
    else
      Rails.logger.info("Could not find subscription: #{subscription_response.clean_inspect}")
      flash[:error] = subscription_response.error_message
      redirect_to subscription_path(concept_id)
    end
  end

  def create
    authorize :subscription
    @subscription = subscription_params
    @subscription['EmailAddress'] = get_subscriber_email(@subscription['SubscriberId'])
    native_id = "mmt_subscription_#{SecureRandom.uuid}"

    subscription_response = cmr_client.ingest_subscription(@subscription.to_json, current_user.provider_id, native_id, token)
    if subscription_response.success?
      flash[:success] = I18n.t('controllers.subscriptions.create.flash.success')
      redirect_to subscription_path(subscription_response.parsed_body['result']['concept_id'])
    else
      Rails.logger.error("Creating a subscription failed with CMR Response: #{subscription_response.clean_inspect}")
      flash[:error] = subscription_response.error_message(i18n: I18n.t('controllers.subscriptions.create.flash.error'))

      set_previously_selected_subscriber(@subscription['SubscriberId'])
      render :new
    end
  end

  def update
    authorize :subscription
    @subscription = subscription_params
    @subscription['EmailAddress'] = get_subscriber_email(@subscription['SubscriberId'])

    subscription_response = cmr_client.ingest_subscription(@subscription.to_json, current_user.provider_id, @native_id, token)
    if subscription_response.success?
      flash[:success] = I18n.t('controllers.subscriptions.update.flash.success')
      redirect_to subscription_path(@concept_id)
    else
      Rails.logger.error("Updating a subscription failed with CMR Response: #{subscription_response.clean_inspect}")
      flash[:error] = subscription_response.error_message(i18n: I18n.t('controllers.subscriptions.update.flash.success'))

      set_previously_selected_subscriber(@subscription['SubscriberId'])
      redirect_to edit_subscription_path(@concept_id)
    end
  end

  def destroy
    authorize :subscription

    delete_response = cmr_client.delete_subscription(current_user.provider_id, @native_id, token)
    if delete_response.success?
      flash[:success] = I18n.t('controllers.subscriptions.destroy.flash.success')
      redirect_to subscriptions_path
    else
      Rails.logger.error("Failed to delete a subscription.  CMR Response: #{delete_response.clean_inspect}")
      flash[:error] = delete_response.error_message(i18n: I18n.t('controllers.subscriptions.destroy.flash.error'))
      redirect_to subscription_path(@concept_id)
    end
  end

  private

  def subscription_params
    params.require(:subscription).permit(:Name, :CollectionConceptId, :Query, :SubscriberId, :EmailAddress)
  end

  def subscriptions_enabled?
    redirect_to manage_cmr_path unless Rails.configuration.subscriptions_enabled
  end

  def get_subscriber(subscriber_id)
    if subscriber_id
      # subscriber id must be an array for the urs query
      retrieve_urs_users(Array.wrap(subscriber_id))
    else
      []
    end
  end

  def set_previously_selected_subscriber(subscriber_id)
    # setting up the subscriber for the select box option
    @subscriber = get_subscriber(subscriber_id)

    @subscriber.map! { |s| [urs_user_full_name(s), s['uid']] }
  end

  def get_subscriber_email(subscriber_id)
    subscriber = get_subscriber(subscriber_id).fetch(0, {})
    subscriber.fetch('email_address', nil)
  end

  def add_top_level_breadcrumbs
    add_breadcrumb 'Subscriptions', subscriptions_path
  end

  def fetch_native_id
    @concept_id = params.permit(:id)['id']
    subscription_search_response = cmr_client.get_subscriptions({ 'ConceptId' => @concept_id }, token)
    @native_id = subscription_search_response.body['items'].first['native_id'] if subscription_search_response.success?
  end
end
