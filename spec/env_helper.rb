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
  # e.g.: parse_env %{ a=b c="d" e='f' g="h i" foo="bar=' baz='quux" brakeman_options="--skip-files app/views/" }
  # => {"a"=>"b", "c"=>"d", "e"=>"f", "g"=>"h i", "foo"=>"bar=' baz='quux", "brakeman_options"=>"--skip-files app/views/"}
  # inspired by Dotenv::Parser.call(environment_text).each { |k,v| ENV[k] = v }
  # https://github.com/bkeepers/dotenv/blob/master/lib/dotenv/parser.rb
  def parse_env(env_text)
    # test: http://rubular.com/r/9sTawyW4Ix
    text_reg = /(?<key>\b\w+\b)\s*=\s*(?:"(?<v1>[^"]*)"|'(?<v2>[^']*)'|(?<v3>[^"'<>\s]+))/
    hash = {}
    env_text.scan(text_reg).each do |key, v1, v2, v3|
      hash[key] = [v1, v2, v3].compact.join
    end
    hash
  end
end
