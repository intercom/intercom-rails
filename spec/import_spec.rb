require 'import_spec_helper'

describe IntercomRails::Import do
  context 'misconfiguration' do
    it 'raises error if not production environment' do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))

      expect { IntercomRails::Import.run }.to raise_error(IntercomRails::ImportError) do |error|
        expect(error.message).to eq("You can only import your users from your production environment")
      end
    end

    it 'raises error if no user class found' do
      allow_any_instance_of(IntercomRails::Import).to receive(:user_klass).and_return(nil)

      expect { IntercomRails::Import.run }.to raise_error(IntercomRails::ImportError) do |error|
        expect(error.message).to eq("We couldn't find your user class, please set one in config/initializers/intercom_rails.rb")
      end
    end

    it 'raises error if unsupported user class' do
      allow_any_instance_of(IntercomRails::Import).to receive(:user_klass).and_return(Class)

      expect { IntercomRails::Import.run }.to raise_error(IntercomRails::ImportError) do |error|
        expect(error.message).to eq("Only ActiveRecord and Mongoid models are supported")
      end
    end

    it 'raises error if no api_key set' do
      IntercomRails.config.api_key = nil
      expect { IntercomRails::Import.run }.to raise_error(IntercomRails::ImportError) do |error|
        expect(error.message).to eq("Please add an Intercom API Key to config/initializers/intercom.rb")
      end
    end
  end

  context 'mongoid' do
    it "imports" do
      IntercomRails.config.user.model = proc { ExampleMongoidUserModel }
      import = IntercomRails::Import.new
      expect(import).to receive(:map_to_users_for_wire).with(ExampleMongoidUserModel.all).and_call_original
      expect(import).to receive(:send_users).and_return('failed' => [])
      import.run
    end
  end

  context 'status output' do
    it 'prints details of what it is doing' do
      import = IntercomRails::Import.new(:status_enabled => true)
      expect(import).to receive(:send_users).and_return('failed' => [1])
      expect(import).to receive(:batches).and_yield(nil, 3)

      expect(capturing_stdout { import.run }).to eq(<<-output
* Found user class: User
* Intercom API key found
* Sending users in batches of 100:
..F
* Successfully created 2 users
* Failed to create 1 user, this is likely due to bad data
                                                 output
                                                 )
    end
  end

  context 'batch size' do
    it 'has a default' do
      expect(IntercomRails::Import.new.max_batch_size).to eq(100)
    end
    it 'is settable' do
      expect(IntercomRails::Import.new(:max_batch_size => 50).max_batch_size).to eq(50)
    end
    it 'has a hard limit' do
      expect(IntercomRails::Import.new(:max_batch_size => 101).max_batch_size).to eq(100)
    end
  end

  context 'companies' do
    it 'prepares companies for import' do
      import = IntercomRails::Import.new
      u = dummy_user
      u.instance_eval do
        def apps
          [dummy_company]
        end
      end

      allow(User).to receive(:find_in_batches).and_yield([u])

      IntercomRails.config.user.company_association = Proc.new { |user| user.apps }

      prepare_for_batch_users = nil
      allow(import).to receive(:prepare_batch) {|users| prepare_for_batch_users = users}
      allow(import).to receive(:send_users).and_return('failed' => [])

      import.run

      expect(prepare_for_batch_users[0][:companies].length).to eq(1)
    end
  end
end