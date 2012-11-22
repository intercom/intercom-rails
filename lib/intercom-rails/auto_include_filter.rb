module IntercomRails

  class AutoIncludeFilter

    CLOSING_BODY_TAG = %r{</body>}

    def self.filter(controller)
      auto_include_filter = new(controller)
      return unless auto_include_filter.include_javascript?

      auto_include_filter.include_javascript!
    end

    attr_reader :controller

    def initialize(kontroller)
      @controller = kontroller 
    end

    def include_javascript! 
      response.body = response.body.gsub(CLOSING_BODY_TAG, intercom_script_tag.output + '\\0')
    end

    def include_javascript?
      !intercom_script_tag_called_manually? &&
      html_content_type? &&
      response_has_closing_body_tag? &&
      intercom_script_tag.valid?
    end

    private
    def response
      controller.response
    end

    def html_content_type?
      response.content_type == 'text/html'
    end

    def response_has_closing_body_tag?
      !!(response.body[CLOSING_BODY_TAG])
    end

    def intercom_script_tag_called_manually?
      controller.instance_variable_get(SCRIPT_TAG_HELPER_CALLED_INSTANCE_VARIABLE)
    end

    def intercom_script_tag
      @script_tag ||= ScriptTag.new(:find_current_user_details => true, :controller => controller)
    end

  end

end
