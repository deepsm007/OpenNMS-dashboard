module ApplicationHelper

	# performance monitor start

$storageColorList = Array.new
USER = "admin"
PASSWORD = "admin"
$cpuUsage = ""
$cpuColor = ""
$storageColor = ""
$memoryColor = ""

def clearStorageList
    storageColorList = Array.new
end

    def getColor
        x=""
          if $storageColorList.include? 'red'
            x= "red" 
          elsif !$storageColorList.include? 'amber'
            x= "green"
          else
              x="amber"
          end

        if $cpuColor == 'red' || (x== 'red') || ($memoryColor == 'red')
          return "red"
        elsif $cpuColor == 'green' || (x == 'green') || ($memoryColor == 'green')
          return "green"
        else
          return "amber"
       end
   end

def getCPUusage(id)
  starttime = (DateTime.now.strftime('%Q')).to_s
  require 'yaml' 
  @config = YAML.load_file(Rails.root.join('config/config.yml'))

  begin  # "try" block
    response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/measurements/node["+id+ "].nodeSnmp[]/cpuPercentBusy?start="+starttime, user: 'admin',
      password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
    
        cpuPercentBusy_response_hash = JSON.parse(response.body)
        @cpuPercentBusy_responseData=cpuPercentBusy_response_hash['columns'][0]['values']
      rescue # optionally: `rescue Exception => ex`
        puts 'I am rescued.'
        $cpuColor = "red";
        averageCPU = 0;
        return averageCPU;
     
  # if x['id']!="235"
  end
      min = 0
      max = 0

      min = @cpuPercentBusy_responseData[0]
      max = @cpuPercentBusy_responseData[0]
      for z in 0..((@cpuPercentBusy_responseData.length)-1) do
        if !@cpuPercentBusy_responseData[z] == "NaN"
          if @cpuPercentBusy_responseData[z] < min 
            min = @cpuPercentBusy_responseData[z]
          end
          if @cpuPercentBusy_responseData[z] > max
            max = @cpuPercentBusy_responseData[z]
          end
        end
      end

      averageCPU = (min + max) / 2
      if !(averageCPU>=0) 
        $cpuColor = "green";
        return 0;
      puts @config['config']['CPU_minimum_percentage']
      if averageCPU <= @config['config']['CPU_minimum_percentage']
        $cpuColor = "green"
      elsif averageCPU > @config['config']['CPU_minimum_percentage'] && averageCPU <= @config['config']['CPU_maximum_percentage']
        $cpuColor = "amber"
      else
        $cpuColor = "red"
      end
    return averageCPU
end


def getPhysicalMemoryUsed(id)
  require 'yaml' 
  @config = YAML.load_file(Rails.root.join('config/config.yml'))
  starttime = (DateTime.now.strftime('%Q')).to_s
  begin  # "try" block

    response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/measurements/node["+id+ "].hrStorageIndex[PhysicalMemory]/hrStorageSize?start="+starttime, user: 'admin',
      password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
    
        hrStorageSize_response_hash = JSON.parse(response.body)
        @hrStorageSize_responseData=hrStorageSize_response_hash['columns'][0]['values']
      rescue # optionally: `rescue Exception => ex`
        puts 'I am rescued.'
        $memoryColor = "red";
        return 0;
    
    # if x['id']!="235"
  end
    
        totalMemory = 0
        for z in 0..((@hrStorageSize_responseData.length)-1) do
          if !@hrStorageSize_responseData[z] ==  "NaN"
            totalMemory = hrStorageSize_responseData[z]
            break
          end
        end

        response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/measurements/node["+id+ "].hrStorageIndex[PhysicalMemory]/hrStorageUsed?start="+starttime, user: 'admin',
      password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
    
        hrStorageUsed_response_hash = JSON.parse(response.body)
        @hrStorageUsed_responseData=hrStorageUsed_response_hash['columns'][0]['values']

        memoryUsed = ""

        count =0
        sum = 0
        for z in 0..((@hrStorageUsed_responseData.length)-1) do
          if !@hrStorageUsed_responseData[z] ==  "NaN"
            count++
            sum = sum + @hrStorageUsed_responseData[z]
          end
        end

        memoryUsed = sum / count


        percentmemoryUsed = (memoryUsed * 1.0/totalMemory) * 100.0

        if percentmemoryUsed <= @config['config']['Memory_minimum_percentage']
            $memoryColor = "green"
          elsif percentmemoryUsed > @config['config']['Memory_minimum_percentage'] && percentmemoryUsed <= @config['config']['Memory_maximum_percentage']
            $memoryColor = "amber"
          else
            $memoryColor = "red"
          end

          return percentmemoryUsed
          
end

def getStorageUsed(id , drive)
  starttime=(DateTime.now.strftime('%Q')).to_s
require 'yaml' 
@config = YAML.load_file(Rails.root.join('config/config.yml'))

begin  # "try" block
   response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/measurements/node["+id+ "].hrStorageIndex["+ drive + "]/hrStorageSize?start=" +starttime, user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
      hrStorageSize_response_hash = JSON.parse(response.body)
      @hrStorageSize_responseData=hrStorageSize_response_hash['columns'][0]['values']
    rescue # optionally: `rescue Exception => ex`
      puts 'I am rescued.'
      $storageColor = "red";
			return 0;
  
  # if x['id']!="235"
  end
totalStorage = 0

    for z in 0..((@hrStorageSize_responseData.length)-1) do
        if !@hrStorageSize_responseData[z] ==  "NaN"
          totalStorage = @hrStorageSize_responseData[z]
        end
      end

      response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/measurements/node["+id+ "].hrStorageIndex["+ drive + "]/hrStorageSize?start=" +starttime, user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
      hrStorageSize_response_hash = JSON.parse(response.body)
      @hrStorageSize_responseData=hrStorageSize_response_hash['columns'][0]['values']

      storageUsed = ""

      count =0
      sum =0
       for z in 0..((@hrStorageSize_responseData.length)-1) do
        if !@hrStorageSize_responseData[z] ==  "NaN"
          count++
          sum = sum + @hrStorageSize_responseData[z]
        end
      end
storageUsed = sum / count

if storageUsed != 0
  percentStorageUsed = (storageUsed * 1.0 / totalStorage) * 100.0

   if percentStorageUsed <= @config['config']['Memory_minimum_percentage']
          $memoryColor = "green"
        elsif percentStorageUsed > @config['config']['Memory_minimum_percentage'] && percentStorageUsed <= @config['config']['Memory_maximum_percentage']
          $memoryColor = "amber"
        else
          $memoryColor = "red"
        end

        storageColorList.push($storageColor)

        return percentStorageUsed

      else
        return 0
      end
    end

end

def isYes(drive)
 require 'yaml' 
 @config = YAML.load_file(Rails.root.join('config/config.yml'))
 return @config['config'][drive]
 

end

# performance monitor end
end
