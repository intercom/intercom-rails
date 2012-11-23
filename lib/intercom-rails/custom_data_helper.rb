module IntercomRails

  module CustomDataHelper
    
    # This helper allows custom data attributes to be added to a user
    # for the current request from within the controller. e.g.
    #
    # def destroy
    #   intercom_custom_data['canceled_at'] = Time.now
    #   ...
    # end
    def intercom_custom_data
      @_request_specific_intercom_custom_data ||= {}
    end

  end

end
