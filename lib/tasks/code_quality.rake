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
    task :default => [:rubycritic, :rubocop] do; end

    # desc "prepare dir"
    task :prepare => :helpers do
      @report_dir = "tmp/code_quality/quality_audit"
      prepare_dir @report_dir

      def report_dir
        @report_dir
      end
    end

    desc "rubycritic"
    # e.g.: rake code_quality:quality_audit:rubycritic lowest_score=94.5
    task :rubycritic => :prepare do
      options = options_from_env(:lowest_score)
      run_audit "Rubycritic - static analysis gems such as Reek, Flay and Flog to provide a quality report of your Ruby code." do
        report = `rubycritic -p #{report_dir}/rubycritic app lib`
        puts report

        # if config lowest_score then audit it with report score
        if options[:lowest_score]
          if report.last(20) =~ /Score: (.+)/
            report_score = $1.to_f
            lowest_score = options[:lowest_score].to_f
            audit_faild "Report score #{colorize(report_score, :yellow)} is lower then #{colorize(lowest_score, :yellow)}, must improve your code quality or set a higher #{colorize("lowest_score", :black, :white)}" if report_score < lowest_score
          end
        end
      end
    end

    desc "rubocop - audit coding style"
    # e.g.: rake code_quality:quality_audit:rubocop max_offenses=100
    # options:
    #   config_formula: use which formula for config, supports "github, "rails" or path_to_your_local_config.yml, default is "github"
    #   cli_options: pass extract options, e.g.: cli_options="--show-cops"
    #   max_offenses: if config max_offenses then audit it with detected offenses number in report, e.g.: max_offenses=100
    task :rubocop => :prepare do
      run_audit "rubocop - RuboCop is a Ruby static code analyzer. Out of the box it will enforce many of the guidelines outlined in the community Ruby Style Guide." do
        options = options_from_env(:config_formula, :cli_options, :max_offenses)

        config_formulas = {
          'github' => 'https://github.com/github/rubocop-github',
          'rails' => 'https://github.com/rails/rails/blob/master/.rubocop.yml'
        }

        # prepare cli options
        config_formula = options.fetch(:config_formula, 'github')
        if config_formula && File.exists?(config_formula)
          config_file = config_formula
          puts "Using config file: #{config_file}"
        else
          gem_config_dir = File.expand_path("../../../config", __FILE__)
          config_file    = "#{gem_config_dir}/rubocop-#{config_formula}.yml"
          puts "Using config formula: [#{config_formula}](#{config_formulas[config_formula]})"
        end
        report_path = "#{report_dir}/rubocop-report.html"

        # generate report
        report = `rubocop -c #{config_file} -S -R -P #{options[:cli_options]} --format offenses --format html -o #{report_path}`
        puts report
        puts "Report generated to #{report_path}"

        # if config max_offenses then audit it with detected offenses number in report
        if options[:max_offenses]
          if report.last(20) =~ /(\d+) *Total/
            detected_offenses = $1.to_i
            max_offenses = options[:max_offenses].to_i
            audit_faild "Detected offenses #{colorize(detected_offenses, :yellow)} is more then #{colorize(max_offenses, :yellow)}, must improve your code quality or set a lower #{colorize("max_offenses", :black, :white)}" if detected_offenses > max_offenses
          end
        end
      end
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
      flag = colorize("[AUDIT FAILED]", :red, :yellow)
      abort "#{flag} #{msg}"
    end

    # e.g.: options_from_env(:a, :b) => {:a => ..., :b => ... }
    def options_from_env(*keys)
      ENV.to_h.slice(*keys.map(&:to_s)).symbolize_keys!
    end

    # set text color, background color using ANSI escape sequences, e.g.:
    #   colors = %w(black red green yellow blue pink cyan white default)
    #   colors.each { |color| puts colorize(color, color) }
    #   colors.each { |color| puts colorize(color, :green, color) }
    def colorize(text, color = "default", bg = "default")
      colors = %w(black red green yellow blue pink cyan white default)
      fgcode = 30; bgcode = 40
      tpl = "\e[%{code}m%{text}\e[0m"
      cov = lambda { |txt, col, cod| tpl % {text: txt, code: (cod+colors.index(col.to_s))} }
      ansi = cov.call(text, color, fgcode)
      ansi = cov.call(ansi, bg, bgcode) if bg.to_s != "default"
      ansi
    end
  end

end
