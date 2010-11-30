#!/usr/bin/env ruby
require 'rubygems'
require 'commander/import'


module Conll
  Token = Struct.new(:id, :form, :lemma, :cpos, :pos, :feats, :head_id, :deprel, :lhead_id, :ldeprel, :phead_id, :pdeprel)

  class Token
    attr_accessor :sentence

    def self.parse(line)
      fields = line.split(/\t/)
      fields = fields[0..2] + fields[3..-1].collect do |f|
        # Interpret dash/underscore as "missing value" and use nil instead
        (f == '_' or f == '-') ? nil : f
      end unless fields.size < 4
      # Pass in a reference to the sentence
      Token.new(*fields)
    end

    def initialize(*vals)
      super(*vals)
      # Split features
      @features = vals[5].split(/\|/) unless vals[5].nil?
    end

    # Gives the base-0 index of this token into the sentence
    def index
      self.id.to_i - 1
    end

    def first?
      self.index == 0
    end

    def last?
      self.index == @sentence.tokens.size - 1
    end

    def next
      @sentence.tokens[index + 1]
    end

    def prev
      @sentence.tokens[index - 1]
    end

    def features
      @features ||= []
    end

    def head
      find_token(self.head_id)
    end

    def dependents
      @sentence.tokens.find_all { |tok| tok.head_id == self.id }
    end

    def phead
      find_token(self.phead_id)
    end

    def to_s
      if self.features.size > 0
        self.feats = self.features.to_a.join('|')
      else
        self.feats = nil
      end
      self.values.collect { |val|
        val.nil? ? '_' : val
      }.join("\t")
    end

    def head_correct? gold_token
      self.head.id == gold_token.head.id
    end

    def label_correct? gold_token
      self.deprel == gold_token.deprel
    end

    def correct? gold_token
      head_correct? gold_token and label_correct? gold_token
    end

    def leading(n)
      @sentence.tokens[self.index-n .. self.index-1]
    end

    def trailing(n)
      @sentence.tokens[self.index+1 .. self.index+n]
    end

    private

    def find_token(id)
      if id == '0'
        @sentence.root
      else
        @sentence.tokens[id.to_i - 1]
      end
    end

  end

  class RootToken < Token
    def initialize
      super('0', 'ROOT')
    end
  end
  
end


program :version, '0.1'
program :description, 'Assist in translation factor juggling.'

command :split do |c|
  c.syntax = 'factor split CORPUS'
  c.description = 'Split a factored corpus into separate, unfactored corpora'
  c.option '--skip N', Integer, 'Numbers of factors to skip (e.g. to skip the surface form)'
  c.option '--factors f1,f2,...', 'Names of the factors'
  c.action do |args, options| 
    options.default :skip => 0
    corpus = args.first
    say "Reading factored corpus from #{corpus}"
    outputs = options.factors.split(/,/).collect do |factor| 
      output = "#{corpus}.#{factor}"
      say "Writing #{factor} factors to #{output}"
      File.open(output, 'w') 
    end
    File.foreach(corpus) do |line| 
      factor_sents = line.chomp.split(/ /).collect { |tok| tok.split('|') }.transpose
      options.skip.times do factor_sents.shift end
      outputs.each do |output|
        output << (factor_sents.first * ' ') + "\n"
        factor_sents.shift
      end
    end
    outputs.each do |output|
      output.close
    end
  end
end

command :combine do |c|
  c.syntax = 'factor combine CORPUS [options]'
  c.description = 'Combine a corpus with various factors into a factored corpus'
  c.option '--conll FILE', 'CoNLL file from which to get e.g. word form, POS and dependency label'
  c.option '--clusters FILE', 'PATH file from wcluster from which to read brown clusters'
  c.option '--output FILE', 'Where to put the factored corpus'
  c.action do |args, options|
    corpus = args.first
    say "Using corpus #{corpus}"
    if options.clusters
      say "Reading clusters from #{options.clusters}"
      clusters = {}
      clusters.default = '_'
      File.foreach(options.clusters) do |line|
        line.chomp!
        cluster, form, tmp = line.split("\t")
        clusters[form] = cluster
      end
    else
      clusters = false
    end
    say "Reading POS and DEPREL from CONLL file #{options.conll}"
    conll = File.open(options.conll, 'r') if options.conll
    say "Writing factored corpus to #{options.output}"
    output = File.open(options.output, 'w')
    File.foreach(corpus) do |line|
      line.chomp.split(' ').each do |form|
        output << form
        if options.conll
          tok = Conll::Token.parse(conll.gets.chomp)
          output << "|#{tok.pos}|#{tok.deprel}"
        end
        if clusters 
          output << "|#{clusters[tok.form]}" 
        end
        output << " "
      end
      # End of sentence
      conll.gets if options.conll
      output << "\n"
    end
  end
end

command :prepare_wsd do |c|
  c.syntax 'factor prepare_wsd LEMMAS POS'
  c.description = 'Prepare a context file for word sense disambiguation.'
  c.option '--before N', Integer, 'Number of preceding sentences to include in the context'
  c.option '--after N',  Integer, 'Number of trailing sentences to include in the context'
  c.option '--output FILE', 'Where to put the context file'
  c.action do |args, options|
    options.default :before => 1, :after => 1
    pos_file = File.open(args[1], 'r') 
    output = File.open(options.output, 'w')
    File.foreach(args.first) do |line|
      pos_tags = pos_file.gets.chomp.split(' ')
      id = 'w0'
      ctrl = '1'
      line.chomp.split(' ').each do |form|
        output << [form, pos_tags.shift, id.succ!, ctrl].join('#') + ' '
      end
      # End of sentence
      output << "\n"
    end
  end
end