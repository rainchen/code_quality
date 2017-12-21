namespace :code_quality do

  desc "security audit using bundler-audit, brakeman"
  task :security_audit => [:"security_audit:default"] do; end
  namespace :security_audit do
    # default tasks
    task :default => [:bundler_audit, :brakeman, :resources] do; end

    # desc "prepare dir"
    task :prepare => :helpers do
      @report_dir = "tmp/code_quality/security_audit"
      prepare_dir @report_dir

      def report_dir
        @report_dir
      end
    end

    desc "bundler audit"
    task :bundler_audit => :prepare do
      run_audit "bundler audit - checks for vulnerable versions of gems in Gemfile.lock" do
        # Update the ruby-advisory-db and check Gemfile.lock
        report = `bundle audit check --update`
        File.open("#{report_dir}/bundler-audit-report.txt", 'w') {|f| f.write report }
        puts report
        audit_faild "Must fix vulnerabilities ASAP" unless report =~ /No vulnerabilities found/
      end
    end

    desc "brakeman"
    task :brakeman => :prepare do
      run_audit "Brakeman audit - checks Ruby on Rails applications for security vulnerabilities" do
        `brakeman -o #{report_dir}/brakeman-report.txt -o #{report_dir}/brakeman-report.json`
        puts `cat #{report_dir}/brakeman-report.txt`
        report = JSON.parse(File.read("#{report_dir}/brakeman-report.json"))
        audit_faild "There are #{report["errors"].size} errors, must fix them ASAP." if report["errors"].any?
      end
    end

    # desc "resources url"
    task :resources do
      refs = %w{
        https://github.com/presidentbeef/brakeman
        https://github.com/rubysec/bundler-audit
        http://guides.rubyonrails.org/security.html
        https://github.com/hardhatdigital/rails-security-audit
        https://hakiri.io/blog/ruby-security-tools-and-resources
        https://www.netsparker.com/blog/web-security/ruby-on-rails-security-basics/
        https://www.owasp.org/index.php/Ruby_on_Rails_Cheatsheet
      }
      puts "## Security Resources"
      puts refs.map { |url| "  - #{url}" }
    end
  end

  # TODO: code quality audit
  desc "code quality audit"
  task :quality_audit => [:"quality_audit:default"] do; end
  namespace :quality_audit do
    # default tasks
    task :default do
      puts "PENDING"
    end
  end

  # desc "helper methods"
  task :helpers do
    def run_audit(title, &block)
      puts "## #{title}"
      puts "", "```"
      realtime(&block)
      puts "```", ""
    end

    def realtime(&block)
      realtime = Benchmark.realtime do
        block.call
      end.round
      process_time = humanize_secs(realtime)
      puts "[ #{process_time} ]"
    end

    # p humanize_secs 60
    # => 1m
    # p humanize_secs 1234
    #=>"20m 34s"
    def humanize_secs(secs)
      [[60, :s], [60, :m], [24, :h], [1000, :d]].map{ |count, name|
        if secs > 0
          secs, n = secs.divmod(count)
          "#{n.to_i}#{name}"
        end
      }.compact.reverse.join(' ').chomp(' 0s')
    end

    def prepare_dir(dir)
      FileUtils.mkdir_p dir
    end

    def audit_faild(msg)
      abort "[AUDIT FAILED] #{msg}"
    end
  end

end
