require 'roadworker/dsl'
require 'roadworker/route53-wrapper'

module Roadworker
  class Client

    def initialize(options)
      route53 = AWS::Route53.new({
        :access_key_id     => options[:access_key_id],
        :secret_access_key => options[:secret_access_key],
      })

      @route53 = Route53Wrapper.new(route53, options)
    end

    def apply(source)
      source = source.read if source.kind_of?(IO)
      dsl = DSL.define(source).result

      # XXX: ...
      # walk_hosted_zones(dsl)
    end

    def export
      DSL.convert(@route53.export)
    end

    private

    def walk_hosted_zones(dsl)
      expected = collection_to_hash(dsl, :name)
      actual   = collection_to_hash(@route53.hosted_zones, :name)

      expected.each do |keys, expected_zone|
        name = keys[0]
        actual_zone = actual.delete(keys) || @route53.hosted_zones.create(name)
        walk_rrsets(expected_zone, actual_zone)
      end

      expected.each do |keys, zone|
        name = keys[0]
        # XXX: delete
      end
    end

    def walk_rrsets(expected_zone, actual_zone)
      expected = collection_to_hash(expected_zone.rrsets, :name, :type, :set_identifier)
      actual   = collection_to_hash(actual_zone.rrsets, :name, :type, :set_identifier)

      expected.each do |keys, expected_record|
        name = keys[0]
        type = keys[1]
        set_identifier = keys[2]

        opts = set_identifier ? {:set_identifier => set_identifier} : {}
        actual_record = actual.delete(keys) || actual_zone.rrsets.create(name, type, opts)

        # XXX: update or create
      end

      expected.each do |keys, record|
        name = keys[0]
        type = keys[1]
        set_identifier = keys[2]
        # XXX: delete
      end
    end

    def collection_to_hash(collection, *keys)
      hash = {}

      collection.each do |item|
        key_list = keys.map {|k| item.send(k) }
        hash[key_list] = item
      end

      return hash
    end

  end # Client
end # Roadworker