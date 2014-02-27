module Motion; module Util
  module CodeSign
    class << self
      # @param Boolean valid_only  Whether or not to include only valid code
      #                            sign identities.
      #
      # @returns String  The raw output from querying the `security` DB.
      #
      def query_security_db_for_identities(valid_only)
        command = '/usr/bin/security -q find-identity -p codesigning'
        command << ' -v' if valid_only
        `#{command}`.strip
      end

      # @param Boolean valid_only  Whether or not to include only valid code
      #                            sign identities.
      #
      # @returns Hash{String => String}  The UUIDs and names of the identities.
      #
      def identities(valid_only)
        output = query_security_db_for_identities(valid_only)
        Hash[*output.scan(/(\h{40})\s"(.+?)"/).flatten]
      end

      # @param Boolean valid_only  Whether or not to include only valid code
      #                            sign identities.
      #
      # @returns Array<String>  The names of the identities.
      #
      def identity_names(valid_only)
        identities(valid_only).values
      end
    end
  end
end; end
