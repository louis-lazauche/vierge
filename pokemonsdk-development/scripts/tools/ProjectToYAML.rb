# This script purpose is to allow project to be converted to YAML and Loaded from YAML
#
# To get access to this call :
#   ScriptLoader.load_tool('ProjectToYAML')
#
# To convert project to YAML (in order to push it to git)
#   ProjectToYAML.convert
#
# To restore project from YAML (after pulling from git)
#   ProjectToYAML.restore
module ProjectToYAML
  module_function

  # sort index recursively in a dictionnary
  def deeply_sort_hash(object)
    return object unless object.is_a?(Hash)
    hash = Hash.new
    object.each { |k, v| hash[k] = deeply_sort_hash(v) }
    sorted = hash.sort { |a, b| a[0].to_s <=> b[0].to_s }
    hash.class[sorted]
  end
  
  # When having a Map, sort the events to keep the order consistent
  def reorder_map_events_data(data)
    if data.is_a?(RPG::Map) 
      data.events = deeply_sort_hash(data.events)
    end
    return data
  end
  

  # Convert a project to YAML
  def convert
    files = Dir['Data/*.rxdata'] +
            Dir['Data/Animations/*.dat'] +
            ['Data/PSDK/SystemTags.rxdata',
            'Data/PSDK/Maplinks.rxdata'] -
            ['Data/project_identity.rxdata',
             'Data/Viewport.rxdata',
             'Data/Armors.rxdata',
             'Data/Classes.rxdata',
             'Data/Enemies.rxdata',
             'Data/Exptable.rxdata',
             'Data/Items.rxdata',
             'Data/Scripts.rxdata',
             'Data/Skills.rxdata',
             'Data/States.rxdata',
             'Data/Troops.rxdata',
             'Data/Weapons.rxdata']
    files.each do |filename|
      print "\r#{filename}".ljust(60)
      data = reorder_map_events_data(load_data(filename))
      File.write(filename + '.yml', YAML.dump(data))
    end
    puts "\rSuccess!".ljust(61)
    nil
  end

  # Restore a project from YAML
  def restore
    files = Dir['Data/*.rxdata.yml'] +
            Dir['Data/Animations/*.dat.yml'] +
            ['Data/PSDK/SystemTags.rxdata.yml',
            'Data/PSDK/Maplinks.rxdata.yml'] -
            ['Data/project_identity.rxdata.yml',
             'Data/Viewport.rxdata.yml',
             'Data/Armors.rxdata.yml',
             'Data/Classes.rxdata.yml',
             'Data/Enemies.rxdata.yml',
             'Data/Exptable.rxdata.yml',
             'Data/Items.rxdata.yml',
             'Data/Scripts.rxdata.yml',
             'Data/Skills.rxdata.yml',
             'Data/States.rxdata.yml',
             'Data/Troops.rxdata.yml',
             'Data/Weapons.rxdata.yml']
    files.each do |filename|
      print "\r#{filename}".ljust(60)
      save_data(YAML.unsafe_load(File.read(filename)), filename.sub(/\.yml$/, ''))
    end
    puts "\rSuccess!".ljust(61)
    nil
  end
end

module LiteRGSS
  class Color
    # List of instance variable for instance_variables
    IVARS = %i[@red @green @blue @alpha]
    # Association from ivar to setter
    FROM_YAML = {
      "@red": :red=,
      "@green": :green=,
      "@blue": :blue=,
      "@alpha": :alpha=
    }
    # Association from ivar to getter
    TO_YAML = {
      "@red": :red,
      "@green": :green,
      "@blue": :blue,
      "@alpha": :alpha
    }

    # Deceive YAML by telling Color has instance variables
    # @return [Array]
    def instance_variables
      IVARS
    end

    # Deceive YAML by giving Color value on ivar request
    # @param ivar [Symbol] name of the instance variable
    # @return [Integer]
    def instance_variable_get(ivar)
      method_name = TO_YAML[ivar]
      return method_name ? send(method_name) : super(ivar)
    end

    # Deceive YAML by setting Color value on ivar setter
    # @param ivar [Symbol] name of the instance variable
    # @param value [Integer] value of the variable
    def instance_variable_set(ivar, value)
      method_name = FROM_YAML[ivar]
      return method_name ? send(method_name, value) : super(ivar, value)
    end
  end
  class Tone
    # List of instance variable for instance_variables
    IVARS = %i[@red @green @blue @gray]
    # Association from ivar to setter
    FROM_YAML = {
      "@red": :red=,
      "@green": :green=,
      "@blue": :blue=,
      "@gray": :gray=
    }
    # Association from ivar to getter
    TO_YAML = {
      "@red": :red,
      "@green": :green,
      "@blue": :blue,
      "@gray": :gray
    }

    # Deceive YAML by telling Tone has instance variables
    # @return [Array]
    def instance_variables
      IVARS
    end

    # Deceive YAML by giving Tone value on ivar request
    # @param ivar [Symbol] name of the instance variable
    # @return [Integer]
    def instance_variable_get(ivar)
      method_name = TO_YAML[ivar]
      return method_name ? send(method_name) : super(ivar)
    end

    # Deceive YAML by setting Tone value on ivar setter
    # @param ivar [Symbol] name of the instance variable
    # @param value [Integer] value of the variable
    def instance_variable_set(ivar, value)
      method_name = FROM_YAML[ivar]
      return method_name ? send(method_name, value) : super(ivar, value)
    end
  end
end
class Table
  # List of instance variable for instance_variables
  IVARS = %i[@data]
  # Tag telling to create a new table
  INIT_TAG = 'init '
  # TAG telling to set the z
  Z_TAG = 'z = '
  # Deceive YAML by giving fake table data
  # @return [Array]
  def instance_variables
    IVARS
  end

  # Deceive YAML on instance_variable_get
  # @param ivar [Symbol] name of the instance variable
  # @return [String]
  def instance_variable_get(ivar)
    return super(ivar) if ivar != :@data

    output = [xsize, ysize, zsize][0, dim].join(' ')
    output = "#{INIT_TAG}#{output.empty? ? '1' : output}\n"
    zsize.times do |z|
      output << "#{Z_TAG}#{z}\n"
      ysize.times do |y|
        output << xsize.times.map { |x| self[x, y, z] }.join(' ')
        output << "\n"
      end
    end
    return output
  end

  # Deceive YAML on instance_variable_set
  # @param ivar [Symbol] name of the instance variable
  # @param value [String] value of the table
  def instance_variable_set(ivar, value)
    return super(ivar, value) if ivar != :@data

    atv = proc { |str| str.split(' ').collect(&:to_i) }

    z = 0
    y = 0

    value.each_line do |line|
      if line.start_with?(INIT_TAG)
        send(:initialize, *atv.call(line.split(INIT_TAG).last))
      elsif line.start_with?(Z_TAG)
        z = line.delete(Z_TAG).to_i
        y = 0
      else
        atv.call(line).each_with_index do |cell, x|
          self[x, y, z] = cell
        end
        y += 1
      end
    end
  end
end

module AlphaSortIvar
  def instance_variables
    ivar_list = super
    ivar_list.sort!
    return ivar_list
  end
end

Object.prepend(AlphaSortIvar)
