module ApplicationHelper

	# performance monitor start

storageColorList = Array.new
USER = "admin"
PASSWORD = "admin"
cpuUsage = ""
cpuColor = ""
storageColor = ""
memoryColor = ""

def clearStorageList
    storageColorList = Array.new
end

    def getColor
        x=""
          if storageColorList.include? 'red'
            x= "red"
          elsif !storageColorList.include? 'amber'
            x= "green"
          else
              x="amber"
          end

        if cpuColor.include? 'red' || (x.include? 'red') || (memoryColor.include? 'red')
          return "red"
        elsif cpuColor.include? 'green' || (x.include? 'green') || (memoryColor.include? 'green')
          return "green"
        else
          return "amber"
       end
   end

def getCPUusage(id)
  starttime = (DateTime.now.strftime('%Q')).to_s
require 'yaml' 
@config = YAML.load_file('D:\Public_safety\dashboard2\config\config.yml')
   response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/measurements/node["+id+ "].nodeSnmp[]/cpuPercentBusy?start="+starttime, user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
      cpuPercentBusy_response_hash = JSON.parse(response.body)
      @cpuPercentBusy_responseData=cpuPercentBusy_response_hash['columns'][0]['values']

      min = 0
      max = 0

      min = @cpuPercentBusy_responseData[0]
      max = @cpuPercentBusy_responseData[0]
      for z in 0..((@cpuPercentBusy_responseData.length)-1) do
        if !@cpuPercentBusy_responseData[z].include? "NaN"
          if @cpuPercentBusy_responseData[z] < min 
            min = @cpuPercentBusy_responseData[z]
          end
          if @cpuPercentBusy_responseData[z] > max
            max = @cpuPercentBusy_responseData[z]
          end
        end
      end

      averageCPU = (min + max) / 2

      if averageCPU <= @config['CPU_minimum_percentage']
        cpuColor = "green"
      elsif averageCPU > @config['CPU_minimum_percentage'] && averageCPU <= @config['CPU_maximum_percentage']
        cpuColor = "amber"
      else
        cpuColor = "red"
      end
    return averageCPU
end

def getPhysicalMemoryUsed(id)
  starttime = (DateTime.now.strftime('%Q')).to_s
require 'yaml' 
@config = YAML.load_file('config.yml')
  response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/measurements/node["+id+ "].hrStorageIndex[PhysicalMemory]/hrStorageSize?start="+starttime, user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
      hrStorageSize_response_hash = JSON.parse(response.body)
      @hrStorageSize_responseData=hrStorageSize_response_hash['columns'][0]['values']

      totalMemory = 0
      for z in 0..((@hrStorageSize_responseData.length)-1) do
        if !@hrStorageSize_responseData[z].include? "NaN"
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
        if !@hrStorageUsed_responseData[z].include? "NaN"
          count++
          sum = sum + @hrStorageUsed_responseData[z]
        end
      end

      memoryUsed = sum / count

      percentmemoryUsed = (memoryUsed * 1.0/totalMemory) * 100.0

       if percentmemoryUsed <= @config['Memory_minimum_percentage']
          memoryColor = "green"
        elsif percentmemoryUsed > @config['Memory_minimum_percentage'] && percentmemoryUsed <= @config['Memory_maximum_percentage']
          memoryColor = "amber"
        else
          memoryColor = "red"
        end

        return percentmemoryUsed
          
end

def getStorageUsed(id , drive)
  starttime=(DateTime.now.strftime('%Q')).to_s
require 'yaml' 
@config = YAML.load_file('config.yml')
   response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/measurements/node["+id+ "].hrStorageIndex["+ drive + "]/hrStorageSize?start=" +starttime, user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
      hrStorageSize_response_hash = JSON.parse(response.body)
      @hrStorageSize_responseData=hrStorageSize_response_hash['columns'][0]['values']

totalStorage = 0

    for z in 0..((@hrStorageSize_responseData.length)-1) do
        if !@hrStorageSize_responseData[z].include? "NaN"
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
        if !@hrStorageSize_responseData[z].include? "NaN"
          count++
          sum = sum + @hrStorageSize_responseData[z]
        end
      end
storageUsed = sum / count

if storageUsed != 0
  percentStorageUsed = (storageUsed * 1.0 / totalStorage) * 100.0

   if percentStorageUsed <= @config['Memory_minimum_percentage']
          memoryColor = "green"
        elsif percentStorageUsed > @config['Memory_minimum_percentage'] && percentStorageUsed <= @config['Memory_maximum_percentage']
          memoryColor = "amber"
        else
          memoryColor = "red"
        end

        storageColorList.push(storageColor)

        return percentStorageUsed

      else
        return 0
      end
    end

end

def isYes(drive)
 require 'yaml' 
@config = YAML.load_file('D:\Public_safety\dashboard2\config\config.yml')
  if  @config[drive+"_drive"].include? 'yes'
    return true
  else
    return false
  end

end

# performance monitor end

