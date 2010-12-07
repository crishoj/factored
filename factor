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
  c.syntax = 'factor combine CORPUS FACTOR1, FACTOR2, ... [options]'
  c.description = 'Combine various translation factors into a factored corpus'
  c.option '--output FILE', 'Where to put the factored corpus'
  c.action do |args, options|
    corpus = args.shift
    factor_inputs = args.collect do |filename| 
      say "Reading factors from #{filename}"
      File.open(filename, 'r')
    end
    say "Writing factored corpus to #{options.output}"
    output = File.open(options.output, 'w')
    File.foreach(corpus) do |line|
      factors = factor_inputs.collect { |f| f.gets.chomp.split(' ') }
      line.chomp.split(' ').each do |form|
        token_factors = [form] + factors.collect { |f| f.shift }
        output << token_factors.join('|') + ' '
      end
      # End of sentence
      output << "\n"
    end
  end
end

command :conll_extract do |c|
  c.syntax = 'factor conll_extract CONLL [options]'
  c.description = 'Extract translation factors (POS and DEPREL) from a CONLL parse'
  c.option '--output-pos FILE', 'Where to put the POS tags'
  c.option '--output-deprel FILE', 'Where to put the DEPRELs'
  c.action do |args, options|
    conll = args.first
    say "Reading CONLL file #{conll}"
    say "Writing POS factors to #{options.output_pos}"
    say "Writing DEPREL factors to #{options.output_deprel}"
    pos_output = File.open(options.output_pos, 'w')
    deprel_output = File.open(options.output_deprel, 'w')
    File.foreach(conll) do |line|
      line.chomp!
      if line.empty?
        pos_output << "\n"
        deprel_output << "\n"
      else
        tok = Conll::Token.parse(line)
        pos_output << tok.pos
        pos_output << ' '
        deprel_output << tok.deprel
        deprel_output << ' '
      end
    end
  end
end

command :cluster_extract do |c|
  c.syntax = 'factor cluster_extract CORPUS PATHS [options]'
  c.description = "Create a factor file with word clusters"
  c.option '--output FILE', 'Where to put the factor file'
  c.action do |args, options|
    corpus_file = args.first
    cluster_file = args.last
    say "Reading clusters from #{cluster_file}"
    clusters = {}
    clusters.default = '_'
    File.foreach(cluster_file) do |line|
      line.chomp!
      cluster, form, tmp = line.split("\t")
      clusters[form] = cluster
    end
    say "Writing output to #{options.output}"
    output = File.open(options.output, 'w')
    File.foreach(corpus_file) do |line|
      output << line.chomp.split(' ').collect { |form| clusters[form] }.join(' ') + "\n"
    end
  end
end

command :prepare_wsd do |c|
  c.syntax = 'factor prepare_wsd LEMMAS POS'
  c.description = 'Prepare a context file for word sense disambiguation.'
  c.option '--before N', Integer, 'Number of preceding sentences to include in the context'
  c.option '--after N',  Integer, 'Number of trailing sentences to include in the context'
  c.option '--output FILE', 'Where to put the context file'
  c.action do |args, options|
    options.default :before => 1, :after => 1
    pos_file = File.open(args[1], 'r') 
    output = File.open(options.output, 'w')
    sent_num = 0
    File.foreach(args.first) do |line|
      break if line.chomp.empty?
      sent_num += 1
      pos_tags = pos_file.gets.chomp.split(' ')
      id = 0
      ctrl = 1
      for_wsd = line.chomp.split(' ').collect { |lemma|
        id = id.succ
        pos = pos_tags.shift
        wsd_pos = case pos
                  when /^NN/, 'N'
                    'n' 
                  when /^VB/, 'V'
                    'v'
                  when /^JJ/
                    'a'
                  when /^RB/
                    'r'
                  when /^[CDEFILMPSTUWX\W]/, 'RP', 'A', 'RG'
                    next
                  else raise "Unhandled POS #{pos} (for lemma: #{lemma})"
                  end
        [lemma, wsd_pos, id, ctrl].join('#')
      }.compact
      unless for_wsd.empty?
        output << "ctx_#{sent_num}\n"
        output << for_wsd.join(' ')
        output << "\n"
      end
    end
  end
end

command :spl_to_wpl do |c|
  c.syntax = 'factor spl_to_wpl SENTS --output OUTPUT'
  c.description = 'Convert a file in a sentence-per-line format to word-per-line'
  c.option '--output OUTPUT', "Where to put the output"
  c.when_called do |args, options|
    output = File.open(options.output, 'w')
    File.foreach(args.first) do |line|
      output << line.chomp.gsub(/ /, "\n")+"\n\n"
    end
  end
end

command :col_to_spl do |c|
  c.syntax = 'factor col_to_spl COLFILE --output OUTPUT'
  c.description = 'Extract a single column from a columnar file and save it in sentence-per-line format'
  c.option '--output OUTPUT', "Where to put the output"
  c.option '--col COL', Integer, "The column to extract, counting from 1"
  c.option '--fallback COL', Integer, "Column to fallback to if the extracted column is empty, counting from 1"
  c.when_called do |args, options|
    options.default :col => 1, :fallback => 1
    output = File.open(options.output, 'w')
    toks = []
    File.foreach(args.first) do |line|
      line.chop!
      if line == ""
        output << toks.join(' ') + "\n"
        toks = []
      else
        cols = line.split("\t")
        if cols[options.col-1] == ""
          toks << cols[options.fallback-1]
        else
          toks << cols[options.col-1]
        end
      end
    end
  end
end

command :wsd_extract do |c|
  c.syntax = 'factor wsd_extract CORPUS SENSES [options]'
  c.description = "Create a factor file with word word senses"
  c.option '--output FILE', 'Where to put the factor file'
  c.action do |args, options|
    corpus_file = args[0]
    sense_file = args[1]
    say "Using corpus #{corpus_file}"
    say "Reading senses from #{sense_file}"
    sense_file = File.open(sense_file)
    say "Writing output to #{options.output}"
    output = File.open(options.output, 'w')
    cur_ctx = "ctx_0"
    sense_file.gets # skip comment
    sense_ctx, id, sense = sense_file.gets.chomp.split(/\s+/)
    File.foreach(corpus_file) do |line|
      cur_ctx.succ!
      cur_id = "0"
      output << line.chomp.split(' ').collect { |form| 
        cur_id.succ!
        #say "id: #{id}, cur_id: #{cur_id}, sense_ctx: #{sense_ctx}, cur_ctx: #{cur_ctx}"
        if cur_ctx == sense_ctx and cur_id == id 
          #say " - using sense: #{sense}"
          ret = sense
          sense_ctx, id, sense = sense_file.gets.chomp.split(/\s+/)
        else
          # no word sense .. use form instead
          #say " - using form: #{form}"
          ret = form
        end 
        ret
      }.join(' ') + "\n"
    end
  end
end
