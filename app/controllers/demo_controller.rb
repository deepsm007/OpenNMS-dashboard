class DemoController < ApplicationController
  def index
    require 'date'
require 'net/http'
require 'net/https'
require 'uri'
require 'yaml' 
@config = YAML.load_file(Rails.root.join('config/config.yml'))
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


for j in 0..((@vmArray.length)-1)
for k in 0..((@vmMap[@vmArray[j]['label']].length)-1)
puts j
puts k
puts @vmMap[@vmArray[j]['label']][k]['down']

end
end

end

end
