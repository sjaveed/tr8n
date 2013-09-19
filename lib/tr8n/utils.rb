#--
# Copyright (c) 2013 Michael Berkovich, tr8nhub.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Tr8n
  class Utils

    def self.normalize_tr_params(label, description, tokens, options)
      return label if label.is_a?(Hash)

      if description.is_a?(Hash)
        return {
          :label        => label,
          :description  => nil,
          :tokens       => description,
          :options      => tokens
        }
      end

      {
        :label        => label,
        :description  => description,
        :tokens       => tokens,
        :options      => options
      }
    end

    def self.guid
      (0..16).to_a.map{|a| rand(16).to_s(16)}.join
    end

    def self.load_json(file_path)
      json = JSON.parse(File.read(file_path))
      return HashWithIndifferentAccess.new(json) if json.is_a?(Hash)
      map = {"map" => json}
      HashWithIndifferentAccess.new(map)[:map]
    end

    def self.load_yml(file_path, for_env = Tr8n::Config.env)
      yml = YAML.load_file("#{Tr8n::Config.root}#{file_path}")
      yml = yml['defaults'].rmerge(yml[for_env] || {}) unless for_env.nil?
      HashWithIndifferentAccess.new(yml)
    end

    def self.sign_and_encode_params(params, secret)
      payload = Base64.encode64(params.merge(:algorithm => 'HMAC-SHA256', :ts => Time.now.to_i).to_json)
      sig = OpenSSL::HMAC.digest('sha256', secret, payload)
      encoded_sig = Base64.encode64(sig)
      data = URI::encode("#{encoded_sig}.#{payload}")
      pp :encoded_sig, encoded_sig
      data
    end

    def self.decode_and_verify_params(signed_request, secret)
      signed_request = URI::decode(signed_request)

      encoded_sig, payload = signed_request.split('.', 2)
      sig = Base64.decode64(encoded_sig)

      data = JSON.parse(Base64.decode64(payload))
      if data['algorithm'].to_s.upcase != 'HMAC-SHA256'
        raise Tr8n::Exception.new("Bad signature algorithm: %s" % data['algorithm'])
      end
      expected_sig = OpenSSL::HMAC.digest('sha256', secret, payload)

      if expected_sig != sig
        raise Tr8n::Exception.new("Bad signature")
      end
      HashWithIndifferentAccess.new(data)
    end

    ######################################################################
    # Author: Iain Hecker
    # reference: http://github.com/iain/http_accept_language
    ######################################################################
    def self.browser_accepted_locales(request)
      request.env['HTTP_ACCEPT_LANGUAGE'].split(/\s*,\s*/).collect do |l|
        l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
        l.split(';q=')
      end.sort do |x,y|
        raise Tr8n::Exception.new("Not correctly formatted") unless x.first =~ /^[a-z\-]+$/i
        y.last.to_f <=> x.last.to_f
      end.collect do |l|
        l.first.downcase.gsub(/-[a-z]+$/i) { |x| x.upcase }
      end
    rescue
      []
    end

  end
end
