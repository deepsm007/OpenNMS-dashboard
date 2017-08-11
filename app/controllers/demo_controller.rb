class DemoController < ApplicationController
  def index
    require 'date'
require 'net/http'
require 'net/https'
require 'uri'

require 'net_http_ssl_fix'

  	require 'rest-client'
      require 'json'









      responseHash = Hash.new
idIPHash = Hash.new
idArray = Array.new

# key = node id , val = isDown?
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

response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/nodes/", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}

#key = id, value = node name
idNodeHash = Hash.new


#array of key value pair of env (repeated)and node id
valueArray = Array.new 

@value= data_hash = JSON.parse(response.body)

 @value['node'].each do |x|
 # key= name , value = id of vm
 idEnvHash = Hash.new
  idNodeHash[x['id']] = x['label']

  idEnvHash[x['foreignSource']] = x['id']
  valueArray.push(idEnvHash)
end



# key = env name , value = isDown 
envArray = Array.new
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
#
# puts vmDownHash

# puts valueArray.first["Dev CFG"]
envArray = Array.new
response = RestClient::Request.execute method: :get, url: "http://10.102.84.101:8980/opennms/rest/foreignSources/", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}

@value= data_hash = JSON.parse(response.body)
@value['foreignSources'].each do |x|
 envArray.push(x['name'])
end

# puts envArray
someHash = Hash.new
envArray.each do |x|
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
isDown = "false"


  @html_data = ""

       opennms_url = "http://10.102.84.101:8980/opennms/rest/"

    # Getting the environment
       response = RestClient::Request.execute method: :get, url: opennms_url+"foreignSources", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
      env_response_hash = JSON.parse(response.body)
      @env_responseData=env_response_hash['foreignSources']

      # Getting VM response
       response = RestClient::Request.execute method: :get, url: opennms_url+"nodes", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
      vm_response_hash = JSON.parse(response.body)
      @vm_responseData=vm_response_hash['node']

       response = RestClient::Request.execute method: :get, url: opennms_url+"outages", user: 'admin',
     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
      outage_response_hash = JSON.parse(response.body)
      @outage_responseData=outage_response_hash['outage']

     # puts "Length"
     # puts @outage_responseData.length
     # Env loop
     for i in 0..((@env_responseData.length)-1) 

            @html_data = @html_data + "<button id=\"envnames"+envStatusArray[i]+"\" onclick=\"myFunction('"+@env_responseData[i]['name']+"')\" class=\"w3-btn w3-block w3-left-align\"> <b>> <i>"+@env_responseData[i]['name']+"</i></b>
             </button><div id=\""+@env_responseData[i]['name']+"\" class=\"w3-container w3-hide\"><br/>&nbsp;&nbsp;Name and details of associated VM<br/>"

          # VM loop
           for j in 0..((@vm_responseData.length)-1) 

              # Condition for ENV and VM
                 if @vm_responseData[j]['foreignSource'] == @env_responseData[i]['name']
               

                       vm_id = @vm_responseData[j]['id']
                     @html_data = @html_data + "<button id=\"vmnames"+vmDownHash[vm_id]+"\" onclick=\"myFunction('"+ @env_responseData[i]['name']+@vm_responseData[j]['label']+"')\" class=\"w3-btn w3-block w3-left-align\">&nbsp;<b>-></b> <b><em>"+@vm_responseData[j]['label']+"</em></b></button><div id=\""+@env_responseData[i]['name']+@vm_responseData[j]['label']+"\" class=\"w3-container w3-hide\">"

                        # Getting IP address from node ID
                       response = RestClient::Request.execute method: :get, url: opennms_url+"nodes/"+vm_id+"/ipinterfaces", user: 'admin',
                     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
                  
                      interface_response_hash = JSON.parse(response.body)
                      @interface_responseData=interface_response_hash['ipInterface']


                        cpuurl = 'http://10.102.84.101:8980/opennms/rest/measurements/node%5B'+@vm_responseData[j]['id']+'%5D.nodeSnmp%5B%5D/cpuPercentBusy?start=1501219316000&maxrows=30'
                 puts cpuurl
     #                  response = RestClient::Request.execute method: :get, url: cpuurl, user: 'admin',
     # password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
  
      cpuUsage_hash = JSON.parse(response.body)
      @cpuUsage_responseData=cpuUsage_hash


                       @html_data = @html_data + " Host Name: <b>"+@interface_responseData.first['hostName']+"</b><br/> <p>"
                       if @vm_responseData[j]['sysDescription']==nil 
                        # puts nil
                        elsif 
                              @html_data = @html_data +cpuurl+" <br/>"+@cpuUsage_responseData.to_s+" <br/>"+ @vm_responseData[j]['sysDescription'] 

                        end
                          dataname = @env_responseData[i]['name']
                          nameOfEnv = dataname.split(" ")

                        @html_data = @html_data + "</p><br/>"


# If condition for host name as IP

# if !@interface_responseData.first['hostName'].include? "10.102"
if @vm_responseData[j]['sysDescription']!=nil
  starttime = (DateTime.now.strftime('%Q').to_i-600000).to_s
  endtime = (DateTime.now.strftime('%Q')).to_s


                        @html_data = @html_data + "<div>
<img class=\"graphImg\" src=\"http://10.102.84.101:8980/opennms/graph/graph.png?resourceId=node%5B"+nameOfEnv[0]+"%2B"+nameOfEnv[1]+"%253A"+@vm_responseData[j]['foreignId']+"%5D.nodeSnmp%5B%5D&report=microsoft.cpuPercentBusy&start="+starttime+"&end="+endtime+"&width=500&height=192\" alt=\"Resource graph: CPU Utilization \">
&nbsp;&nbsp;
<img class=\"graphImg\" src=\"http://10.102.84.101:8980/opennms/graph/graph.png?resourceId=node%5B"+nameOfEnv[0]+"%2B"+nameOfEnv[1]+"%253A"+@vm_responseData[j]['foreignId']+"%5D.nodeSnmp%5B%5D&report=microsoft.memory&start="+starttime+"&end="+endtime+"&width=550&height=235\" alt=\"Resource graph: Memory Usage \">
&nbsp;&nbsp;<br/><br/>
<img class=\"graphImg\" src=\"http://10.102.84.101:8980/opennms/graph/graph.png?resourceId=node%5B"+nameOfEnv[0]+"%2B"+nameOfEnv[1]+"%253A"+@vm_responseData[j]['foreignId']+"%5D.hrStorageIndex%5BPhysicalMemory%5D&amp;report=mib2.storage.usage&amp;start="+starttime+"&amp;end="+endtime+"&amp;width=487&amp;height=172\" alt=\"Resource graph: Storage Utilization\">
&nbsp;&nbsp;
<img class=\"graphImg\" src=\"http://10.102.84.101:8980/opennms/graph/graph.png?resourceId=node%5B"+nameOfEnv[0]+"%2B"+nameOfEnv[1]+"%253A"+@vm_responseData[j]['foreignId']+"%5D.hrStorageIndex%5BC%5D&amp;report=mib2.storage.usage&amp;start="+starttime+"&amp;end="+endtime+"&amp;width=550&amp;height=172\" alt=\"Resource graph: Storage Utilization\">
&nbsp;&nbsp;<br/><br/>
<img class=\"graphImg\" src=\"http://10.102.84.101:8980/opennms/graph/graph.png?resourceId=node%5B"+nameOfEnv[0]+"%2B"+nameOfEnv[1]+"%253A"+@vm_responseData[j]['foreignId']+"%5D.hrStorageIndex%5BD%5D&amp;report=mib2.storage.usage&amp;start="+starttime+"&amp;end="+endtime+"&amp;width=487&amp;height=172\" alt=\"Resource graph: Storage Utilization\">
</div><br/>"

end
                    @html_data = @html_data + "<em>Associated Services</em><br/>"



                      ipaddress = @interface_responseData.first['ipAddress']
                     
                     # Getting services belonging to the IP address
                     response = RestClient::Request.execute method: :get, url: opennms_url+"nodes/"+vm_id+"/ipinterfaces/"+ipaddress+"/services", user: 'admin',
                     password: 'admin', verify_ssl: false, headers: { content_type: 'application/json', accept: 'application/json'}
                  
                      service_response_hash = JSON.parse(response.body)
                      @service_responseData=service_response_hash['service']

      # Service data loop
         for k in 0..((@service_responseData.length)-1)

                @html_data = @html_data + "<button id=\"servicenames"+@service_responseData[k]['down'].to_s+"\" onclick=\"myFunction('"+@env_responseData[i]['name']+@vm_responseData[j]['label']+@service_responseData[k]['serviceType']['name']+"')\" class=\"w3-btn w3-block w3-left-align\">&nbsp;<b>-> "+@service_responseData[k]['serviceType']['name']+"</b></button><div id=\""+@env_responseData[i]['name']+@vm_responseData[j]['label']+@service_responseData[k]['serviceType']['name']+"\" class=\"w3-container w3-hide\"> "

             # for l in 0..((@outage_responseData.length)-1)

              # puts @outage_responseData[l]['monitoredService']['ipInterfaceId']
              # puts @interface_responseData.first['id']
              # puts @outage_responseData[i]['serviceLostEvent']['parameters'].first['value']
                      # if !@outage_responseData[l]['monitoredService']['ipInterfaceId']._empty? && @outage_responseData[l]['monitoredService']['ipInterfaceId'] == @interface_responseData.first['id']
                     
                    # end

              # Condition for service down
                  if @service_responseData[k]['down'] == false
                    @html_data = @html_data + "Service is up<br/>"
                    isDown = "false"
                  elsif 
                    @html_data = @html_data + "Service is down<br/>"
                    isDown = "true"
                     if @outage_responseData[k]['serviceLostEvent']['logMessage'] != "unknown"
                        @html_data = @html_data + "<br/>Error Log message: " + @outage_responseData[k]['serviceLostEvent']['logMessage'] +"<br/>"
                      end

                   

                   end
                    @html_data = @html_data + "</div><br/>"
           end
          
 @html_data = @html_data + "</div><hr/>"
         end
        
       end
        @html_data = @html_data + "</div><hr/>"
     end
  end
end
