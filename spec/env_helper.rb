module EnvHelper
  module_function

  # Using wrap_env allows for the environment to be adjusted only for a specified block of code.
  # refs: https://www.relishapp.com/ScrappyAcademy/rock-candy/docs/helper-methods/wrapping-env
  # https://github.com/ScrappyAcademy/rock_candy/blob/master/lib/rock_candy/helpers.rb
  def wrap_env(envs = {})
    original_envs = ENV.select{ |k, _| envs.has_key? k }
    envs.each{ |k, v| ENV[k] = v }

    yield
  ensure
    envs.each{ |k, _| ENV.delete k }
    original_envs.each{ |k, v| ENV[k] = v }
  end

  # convert a env text to hash
  # e.g.: parse_env("a=b c=d") => {"a" => "b", "c" => "d"}
  # inspired by Dotenv::Parser.call(environment_text).each { |k,v| ENV[k] = v }
  # https://github.com/bkeepers/dotenv/blob/master/lib/dotenv/parser.rb
  def parse_env(env_text)
    reg = /
      ([\w\.]+)         # key
      (?:\s*=\s*|:\s+?) # separator
      (                 # optional value begin
        '(?:\'|[^'])*'  #   single quoted value
        |               #   or
        "(?:\"|[^"])*"  #   double quoted value
        |               #   or
        [^#\n]+         #   unquoted value
      )?                # value end
      \s*
    /x
    hash = {}
    env_text.split(" ").each do |line|
      if (match = line.match(reg))
        key, value = match.captures
        hash[key] = value
      end
    end
    hash
  end
end
