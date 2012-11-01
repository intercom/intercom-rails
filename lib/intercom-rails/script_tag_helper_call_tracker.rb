module IntercomRails
  module ScriptTagHelperCallTracker

    def intercom_script_tag_called!
      @intercom_script_tag_called = true
    end

  end
end
