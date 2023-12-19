
function initMap() {
    var latLong = "";
    var gmarkers = [];
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(function (position) {
       // console.log("Positions are ", position);
  
          latLong = { lat: position.coords.latitude, lng: position.coords.longitude};
          var myLatLng = [
            ["Initial1", -25.363, 131.044 ],
            ["Initial2", -24.363, 131.044]
          ];
          // latLong = { lat: -25.363, lng: 131.044 };
          var version = getParameterByName('version');
     
          $.ajax({
            url: "/MSM/RFP/Plugins/MarvalSoftware/MarvalSoftware.Plugins.MapsIntegration/" + version + "/Handler.ashx?settingToRetrieve=databaseValue&host=" + window.location.protocol + "//" + window.location.host,
            type: 'GET',
            dataType: 'json', // added data type
            success: function(res) {
                console.log(res);
                myLatLng = res;
          const map = new google.maps.Map(document.getElementById("map"), {
            zoom: 15,
            center: latLong,
          });
         
          for (let i = 0; i < myLatLng.length; i++) {
           
             const myLatLn = myLatLng[i];
             offset =Math.random()/1200;
             isEven = offset *4000000 %2 ==0;
             if (isEven) {
               var newLat = myLatLn[1] + offset;
               var newLong = myLatLn[2] + offset;
             } else {
              var newLat = myLatLn[1] - offset;
              var newLong = myLatLn[2] - offset;
             }
             // console.log("Setting lat to %s and long to %s and url to %s", newLat, newLong,myLatLn[3] )
             var marker = new google.maps.Marker({
             position: {lat: newLat, lng: newLong},
             map,
             url: myLatLn[3],
             title: myLatLn[0]
             
          });
          gmarkers.push(marker);
          google.maps.event.addListener(marker, 'click', function() {
            window.location.href = this.url;
        });
        
        map.addListener('zoom_changed', function() {
          for (var i=0; i< gmarkers.length; i++) {
            if (map.getZoom() > 17) {
              gmarkers[i].setLabel(gmarkers[i].getTitle());
            } else {
              gmarkers[i].setLabel(null);
            }
          }
        });
       }
      },
      error: function(data) {
        alert("Error getting data from Marval ", data);
    }
    });
  
          // initialLocation = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
          // map.setCenter(initialLocation);
         
      });
      
  }
  
  }