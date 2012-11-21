namespace :intercom do

  desc "Import your users into intercom"
  task :import => :environment do
    begin
      IntercomRails::Import.run(:status_enabled => true)
    rescue IntercomRails::ImportError => e
      puts e.message
    end
  end

end
