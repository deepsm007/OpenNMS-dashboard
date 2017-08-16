class DemoController < ApplicationController
  def index
    require 'date'
require 'net/http'
require 'net/https'
require 'uri'
require 'yaml' 
@config = YAML.load_file('/config.yml')
  	require 'rest-client'
      require 'json'

      responseHash = Hash.new
idIPHash = Hash.new
idArray = Array.new
@environments = Array.new

@envArray = Array.new
response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/foreignSources/", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}

@value= data_hash = JSON.parse(response.body)
@envArray = @value['foreignSources']
@value['foreignSources'].each do |x|
 @environments.push(x['name'])
end

#array of key value pair of env (repeated)and node id
valueArray = Array.new 

response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/nodes/", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}

#key = id, value = node name
idNodeHash = Hash.new
@vmArray = Array.new


@value= data_hash = JSON.parse(response.body)

# puts @value

@vmArray = @value['node']

# puts vmArray

 @value['node'].each do |x|
 # key= name , value = id of vm
 idEnvHash = Hash.new
  idNodeHash[x['id']] = x['label']
if x['foreignSource']!=nil
  idEnvHash[x['foreignSource']] = x['id']
else
  idEnvHash[nil] = x['id']
  end
  valueArray.push(idEnvHash)

end

# puts valueArray

servicesArray = Array.new
ipInterfaceArray = Array.new
@vmMap = Hash.new

@vmArray.each do |x|
response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/nodes/"+x['id']+ "/ipinterfaces/", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
@value= data_hash = JSON.parse(response.body)

ipInterfaceArray = @value['ipInterface']

response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/nodes/"+x['id']+ "/ipinterfaces/"+ipInterfaceArray.first['ipAddress']+ "/services/", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
@value= data_hash = JSON.parse(response.body)
  
servicesArray = @value["service"]
@vmMap[x['label']]=servicesArray
  end

response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/outages", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
@value= data_hash = JSON.parse(response.body)

outageArray = Array.new

outageArray = @value['outage']

responseList = Array.new

 @startTime = (DateTime.now.strftime('%Q').to_i-600000).to_s
  @endTime = (DateTime.now.strftime('%Q')).to_s





@vmArray.each do |x|
puts x['id']
 url = "http://10.102.84.101:8980/opennms/rest/measurements/node%5B"+x['id']+"%5D.nodeSnmp%5B%5D/cpuPercentBusy?start="+@startTime+"&maxrows=30"

  puts url
begin  # "try" block

response = RestClient::Request.execute method: :get, url: url, user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}

@value= data_hash = JSON.parse(response.body)
puts @value
responseList.push(@value)
rescue # optionally: `rescue Exception => ex`
    puts 'I am rescued.'
end
# if x['id']!="235"
end




@nodeDownHash = Hash.new

response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/nodes/", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
@value= data_hash = JSON.parse(response.body)
@value['node'].each do |x|
  idArray.push(x['id'])
  end

idArray.each do |y|
 response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/nodes/"+y+"/ipinterfaces", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
     @value= data_hash = JSON.parse(response.body)
     responseHash[y] = @value['ipInterface'].first['isDown']
     idIPHash[y] =  @value['ipInterface'].first['ipAddress']
end

idIPHash.each do |id,ip|
response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/nodes/"+id+"/ipinterfaces/"+ip+"/services", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}

@value= data_hash = JSON.parse(response.body)
serviceArray = Array.new
  availHash = Hash.new
  @value['service'].each do |x|
    
  serviceArray.push(x["serviceType"]["name"])
  availHash[x["serviceType"]["name"]]=x["down"]
  
end

@nodeDownHash[id]=availHash
end  





#key = vmID, value = isDown
vmDownHash = Hash.new

@nodeDownHash.each do |nodeID,hass|
  x=false
hass.each do |service,isDown|
 # puts isDown
    if isDown == true
      x = true
      vmDownHash[nodeID]=isDown.to_s
      break
    end
if x == false
  vmDownHash[nodeID]="false"
end
    end
end

# puts vmDownHash

someHash = Hash.new
@envArray.each do |x|
  # puts x
  someArray=Array.new 
  valueArray.each do |y|
    # puts y
someArray.push(y[x])

    end
    someArray.delete(nil)
    someHash[x]=someArray
  end

envStatusArray =Array.new
someHash.each do |envName,idsArray|
  x =false
idsArray.each do |id|
  # puts vmDownHash[id]
  if vmDownHash[id] == "true"
x = true

break

  end
  
  end
    envStatusArray.push(x.to_s)
end


puts envStatusArray

end



































# performance monitor start

# storageColorList = Array.new
# USER = "admin"
# PASSWORD = "admin"
# cpuUsage = ""
# cpuColor = ""
# storageColor = ""
# memoryColor = ""

# def clearStorageList
#     storageColorList = Array.new
# end

#     def getColor
#         x=""
#           if storageColorList.include? 'red'
#             x= "red"
#           elsif !storageColorList.include? 'amber'
#             x= "green"
#           else
#               x="amber"
#           end

#         if cpuColor.include? "red" || x.include? "red" || memoryColor.include? "red"
#           return "red"
#         elsif cpuColor.include? "green" || x.include? "green" || memoryColor.include? "green"
#           return "green"
#         else
#           return "amber"
#        end
#    end

# def getCPUusage(id)

#    response = RestClient::Request.execute method: :get, url: opennms_url+"measurements/node["+id+ "].nodeSnmp[]/cpuPercentBusy?start="+starttime, user: 'admin',
#      password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
#       cpuPercentBusy_response_hash = JSON.parse(response.body)
#       @cpuPercentBusy_responseData=cpuPercentBusy_response_hash['columns'][0]['values']

#       min = 0
#       max = 0

#       min = @cpuPercentBusy_responseData[0]
#       max = @cpuPercentBusy_responseData[0]
#       for z in 0..((@cpuPercentBusy_responseData.length)-1) do
#         if !@cpuPercentBusy_responseData[z].include? "NaN"
#           if @cpuPercentBusy_responseData[z] < min 
#             min = @cpuPercentBusy_responseData[z]
#           end
#           if @cpuPercentBusy_responseData[z] > max
#             max = @cpuPercentBusy_responseData[z]
#           end
#         end
#       end

#       averageCPU = (min + max) / 2

#       if averageCPU <= @config['CPU_minimum_percentage']
#         cpuColor = "green"
#       elsif averageCPU > @config['CPU_minimum_percentage'] && averageCPU <= @config['CPU_maximum_percentage']
#         cpuColor = "amber"
#       else
#         cpuColor = "red"
#       end
#     return averageCPU
# end

# def getPhysicalMemoryUsed(id)

#   response = RestClient::Request.execute method: :get, url: opennms_url+"measurements/node["+id+ "].hrStorageIndex[PhysicalMemory]/hrStorageSize?start="+starttime, user: 'admin',
#      password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
#       hrStorageSize_response_hash = JSON.parse(response.body)
#       @hrStorageSize_responseData=hrStorageSize_response_hash['columns'][0]['values']

#       totalMemory = 0
#       for z in 0..((@hrStorageSize_responseData.length)-1) do
#         if !@hrStorageSize_responseData[z].include? "NaN"
#           totalMemory = hrStorageSize_responseData[z]
#           break
#         end
#       end

#       response = RestClient::Request.execute method: :get, url: opennms_url+"measurements/node["+id+ "].hrStorageIndex[PhysicalMemory]/hrStorageUsed?start="+starttime, user: 'admin',
#      password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
#       hrStorageUsed_response_hash = JSON.parse(response.body)
#       @hrStorageUsed_responseData=hrStorageUsed_response_hash['columns'][0]['values']

#       memoryUsed = ""

#       count =0
#       sum = 0
#       for z in 0..((@hrStorageUsed_responseData.length)-1) do
#         if !@hrStorageUsed_responseData[z].include? "NaN"
#           count++
#           sum = sum + @hrStorageUsed_responseData[z]
#         end
#       end

#       memoryUsed = sum / count

#       percentmemoryUsed = (memoryUsed * 1.0/totalMemory) * 100.0

#        if percentmemoryUsed <= @config['Memory_minimum_percentage']
#           memoryColor = "green"
#         elsif percentmemoryUsed > @config['Memory_minimum_percentage'] && percentmemoryUsed <= @config['Memory_maximum_percentage']
#           memoryColor = "amber"
#         else
#           memoryColor = "red"
#         end

#         return percentmemoryUsed
          
# end

# def getStorageUsed(id , drive)

#    response = RestClient::Request.execute method: :get, url: opennms_url+"measurements/node["+id+ "].hrStorageIndex["+ drive + "]/hrStorageSize?start=" +starttime, user: 'admin',
#      password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
#       hrStorageSize_response_hash = JSON.parse(response.body)
#       @hrStorageSize_responseData=hrStorageSize_response_hash['columns'][0]['values']

# totalStorage = 0

#     for z in 0..((@hrStorageSize_responseData.length)-1) do
#         if !@hrStorageSize_responseData[z].include? "NaN"
#           totalStorage = @hrStorageSize_responseData[z]
#         end
#       end

#       response = RestClient::Request.execute method: :get, url: opennms_url+"measurements/node["+id+ "].hrStorageIndex["+ drive + "]/hrStorageSize?start=" +starttime, user: 'admin',
#      password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
#       hrStorageSize_response_hash = JSON.parse(response.body)
#       @hrStorageSize_responseData=hrStorageSize_response_hash['columns'][0]['values']

#       storageUsed = ""

#       count =0
#       sum =0
#        for z in 0..((@hrStorageSize_responseData.length)-1) do
#         if !@hrStorageSize_responseData[z].include? "NaN"
#           count++
#           sum = sum + @hrStorageSize_responseData[z]
#         end
#       end
# storageUsed = sum / count

# if storageUsed != 0
#   percentStorageUsed = (storageUsed * 1.0 / totalStorage) * 100.0

#    if percentStorageUsed <= @config['Memory_minimum_percentage']
#           memoryColor = "green"
#         elsif percentStorageUsed > @config['Memory_minimum_percentage'] && percentStorageUsed <= @config['Memory_maximum_percentage']
#           memoryColor = "amber"
#         else
#           memoryColor = "red"
#         end

#         storageColorList.push(storageColor)

#         return percentStorageUsed

#       else
#         return 0
#       end
#     end

# end

# def isYes(drive)
 
#   if  @config[drive+"_drive"].include? "yes"
#     return true
#   else
#     return false
#   end

# end

# performance monitor end










# key = node id , val = isDown?


# puts vmDownHash

# puts valueArray.first["Dev CFG"]


# puts envArray

# isDown = "false"



#   end

#   def something 
#     @html_data = ""


#      # puts "Length"
#      # puts @outage_responseData.length
#      # Env loop
#      for i in 0..((@env_responseData.length)-1) 

#             @html_data = @html_data + "<button id=envnames colour="+envStatusArray[i]+"onclick=\"myFunction('"+@env_responseData[i]['name']+"')\" class=\"w3-btn w3-block w3-left-align\" name=\""+@env_responseData[i]['name']+"\"> <b>> <i>"+@env_responseData[i]['name']+"</i></b>
#              </button><div id=\""+@env_responseData[i]['name']+"\" class=\"w3-container w3-hide\" style=\"padding-left: 40px;\">  <br />
#           <h4>
#             <b>></b> Name and details of associated VM
#           </h4>
#           <br />"

#           # VM loop
#            for j in 0..((@vm_responseData.length)-1) 

#               # Condition for ENV and VM
#                  if @vm_responseData[j]['foreignSource'] == @env_responseData[i]['name']
               

#                        vm_id = @vm_responseData[j]['id']
#                      @html_data = @html_data + "<button id=\"vmnames"+vmDownHash[vm_id]+"\" onclick=\"myFunction('"+ @env_responseData[i]['name']+@vm_responseData[j]['label']+"')\" class=\"w3-btn w3-block w3-left-align\">&nbsp;<b>-></b> <b><em>"+@vm_responseData[j]['label']+"</em></b></button><div id=\""+@env_responseData[i]['name']+@vm_responseData[j]['label']+"\" class=\"w3-container w3-hide\">"

#                         # Getting IP address from node ID
#                        response = RestClient::Request.execute method: :get, url: opennms_url+"nodes/"+vm_id+"/ipinterfaces", user: 'admin',
#                      password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
                  
#                       interface_response_hash = JSON.parse(response.body)
#                       @interface_responseData=interface_response_hash['ipInterface']


#                         cpuurl = 'http://10.102.84.101:8980/opennms/rest/measurements/node%5B'+@vm_responseData[j]['id']+'%5D.nodeSnmp%5B%5D/cpuPercentBusy?start=1501219316000&maxrows=30'
#                  puts cpuurl
#      #                  response = RestClient::Request.execute method: :get, url: cpuurl, user: 'admin',
#      # password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
#       cpuUsage_hash = JSON.parse(response.body)
#       @cpuUsage_responseData=cpuUsage_hash
# # puts cpuUsage_hash

#                        @html_data = @html_data + " Host Name: <b>"+@interface_responseData.first['hostName']+"</b><br/> <p>"
#                        if @vm_responseData[j]['sysDescription']==nil 
#                         # puts nil
#                         elsif 
#                               @html_data = @html_data +cpuurl+" <br/>"+@cpuUsage_responseData.to_s+" <br/>"+ @vm_responseData[j]['sysDescription'] 

#                         end
#                           dataname = @env_responseData[i]['name']
#                           nameOfEnv = dataname.split(" ")

#                         @html_data = @html_data + "</p><br/>"


# # If condition for host name as IP

# # if !@interface_responseData.first['hostName'].include? "10.102"
# if @vm_responseData[j]['sysDescription']!=nil
 


#                         @html_data = @html_data + "<div>
# <img class=\"graphImg\" src=\"http://10.102.84.101:8980/opennms/graph/graph.png?resourceId=node%5B"+nameOfEnv[0]+"%2B"+nameOfEnv[1]+"%253A"+@vm_responseData[j]['foreignId']+"%5D.nodeSnmp%5B%5D&report=microsoft.cpuPercentBusy&start="+starttime+"&end="+endtime+"&width=500&height=192\" alt=\"Resource graph: CPU Utilization \">
# &nbsp;&nbsp;
# <img class=\"graphImg\" src=\"http://10.102.84.101:8980/opennms/graph/graph.png?resourceId=node%5B"+nameOfEnv[0]+"%2B"+nameOfEnv[1]+"%253A"+@vm_responseData[j]['foreignId']+"%5D.nodeSnmp%5B%5D&report=microsoft.memory&start="+starttime+"&end="+endtime+"&width=550&height=235\" alt=\"Resource graph: Memory Usage \">
# &nbsp;&nbsp;<br/><br/>
# <img class=\"graphImg\" src=\"http://10.102.84.101:8980/opennms/graph/graph.png?resourceId=node%5B"+nameOfEnv[0]+"%2B"+nameOfEnv[1]+"%253A"+@vm_responseData[j]['foreignId']+"%5D.hrStorageIndex%5BPhysicalMemory%5D&amp;report=mib2.storage.usage&amp;start="+starttime+"&amp;end="+endtime+"&amp;width=487&amp;height=172\" alt=\"Resource graph: Storage Utilization\">
# &nbsp;&nbsp;
# <img class=\"graphImg\" src=\"http://10.102.84.101:8980/opennms/graph/graph.png?resourceId=node%5B"+nameOfEnv[0]+"%2B"+nameOfEnv[1]+"%253A"+@vm_responseData[j]['foreignId']+"%5D.hrStorageIndex%5BC%5D&amp;report=mib2.storage.usage&amp;start="+starttime+"&amp;end="+endtime+"&amp;width=550&amp;height=172\" alt=\"Resource graph: Storage Utilization\">
# &nbsp;&nbsp;<br/><br/>
# <img class=\"graphImg\" src=\"http://10.102.84.101:8980/opennms/graph/graph.png?resourceId=node%5B"+nameOfEnv[0]+"%2B"+nameOfEnv[1]+"%253A"+@vm_responseData[j]['foreignId']+"%5D.hrStorageIndex%5BD%5D&amp;report=mib2.storage.usage&amp;start="+starttime+"&amp;end="+endtime+"&amp;width=487&amp;height=172\" alt=\"Resource graph: Storage Utilization\">
# </div><br/>"

# end
#                     @html_data = @html_data + "<em>Associated Services</em><br/>"



#                       ipaddress = @interface_responseData.first['ipAddress']
                     
#                      # Getting services belonging to the IP address
#                      response = RestClient::Request.execute method: :get, url: opennms_url+"nodes/"+vm_id+"/ipinterfaces/"+ipaddress+"/services", user: 'admin',
#                      password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
                  
#                       service_response_hash = JSON.parse(response.body)
#                       @service_responseData=service_response_hash['service']

#       # Service data loop
#          for k in 0..((@service_responseData.length)-1)

#                 @html_data = @html_data + "<button id=\"servicenames"+@service_responseData[k]['down'].to_s+"\" onclick=\"myFunction('"+@env_responseData[i]['name']+@vm_responseData[j]['label']+@service_responseData[k]['serviceType']['name']+"')\" class=\"w3-btn w3-block w3-left-align\">&nbsp;<b>-> "+@service_responseData[k]['serviceType']['name']+"</b></button><div id=\""+@env_responseData[i]['name']+@vm_responseData[j]['label']+@service_responseData[k]['serviceType']['name']+"\" class=\"w3-container w3-hide\"> "

#              # for l in 0..((@outage_responseData.length)-1)

#               # puts @outage_responseData[l]['monitoredService']['ipInterfaceId']
#               # puts @interface_responseData.first['id']
#               # puts @outage_responseData[i]['serviceLostEvent']['parameters'].first['value']
#                       # if !@outage_responseData[l]['monitoredService']['ipInterfaceId']._empty? && @outage_responseData[l]['monitoredService']['ipInterfaceId'] == @interface_responseData.first['id']
                     
#                     # end

#               # Condition for service down
#                   if @service_responseData[k]['down'] == false
#                     @html_data = @html_data + "Service is up<br/>"
#                     isDown = "false"
#                   elsif 
#                     @html_data = @html_data + "Service is down<br/>"
#                     isDown = "true"
#                      if @outage_responseData[k]['serviceLostEvent']['logMessage'] != "unknown"
#                         @html_data = @html_data + "<br/>Error Log message: " + @outage_responseData[k]['serviceLostEvent']['logMessage'] +"<br/>"
#                       end

                   

#                    end
#                     @html_data = @html_data + "</div><br/>"
#            end
          
#  @html_data = @html_data + "</div><hr/>"
#          end
        
#        end
#         @html_data = @html_data + "</div><hr/>"
#      end
#   end

end
