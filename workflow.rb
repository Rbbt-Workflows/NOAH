require 'rbbt-util'
require 'rbbt/workflow'

Misc.add_libdir if __FILE__ == $0

#require 'rbbt/sources/NOAH'

module NOAH
  extend Workflow

  Rbbt.claim Rbbt.software.opt.NOAH, :proc do |directory|
    raise "Download NOAH into #{directory}"
  end

  CMD.tool "main_NOAH.py", Rbbt.software.opt.NOAH

  CMD.tool "train_NOAH.py", Rbbt.software.opt.NOAH

  Rbbt.claim Rbbt.share.NOAH.data.IEDB, :proc do |file|
    raise "Download IEDB data into #{file}"
  end

  Rbbt.claim Rbbt.share.NOAH.model9, :proc do |file|
    CMD.cmd_log("train_NOAH.py", "-O '#{file}' --length 9 --iedb '#{Rbbt.share.NOAH.data.IEDB.find}'")
  end

  CMD.tool "main_NOAH.py", Rbbt.software.opt.NOAH

  input :input, :text, "CSV with columns peptide and HLA"
  task :predict => :tsv do |csv|

    csv = Open.read(csv) if Misc.is_filename?(csv)
    input_csv = file('input.csv')
    output = file('output')
    Open.write(input_csv, csv.gsub(',',"\t"))
    model = 'Noah.9.pkl'
    CMD.cmd_log("env PYTHONPATH=#{Rbbt.software.opt.find} python #{Rbbt.software.opt.NOAH.find}/main_NOAH.py -i #{input_csv} -o #{output} -model #{Rbbt.share.databases.NOAH[model].find}")

    dumper = TSV::Dumper.new :key_fields => "Pair", :fields => ["Allele", "Peptide", "NOAH_score"], :type => :list
    dumper.init
    TSV.traverse output, :into => dumper, :type => :line do |line|
      hla, pep, score = line.split("\t")
      id = [hla, pep]*"_"
      
      [id, [hla, pep, score]]
    end
  end


end

#require 'NOAH/tasks/basic.rb'

#require 'rbbt/knowledge_base/NOAH'
#require 'rbbt/entity/NOAH'

