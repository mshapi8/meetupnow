<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%@ page import="javax.jdo.PersistenceManager" %>
<%@ page import="javax.jdo.Query" %>
<%@ page import="java.util.Properties" %>
<%@ page import="java.util.List" %>
<%@ page import="meetupnow.MeetupUser" %>
<%@ page import="meetupnow.UserInfo" %>
<%@ page import="meetupnow.PMF" %>
<%@ page import="org.scribe.oauth.*" %>
<%@ page import="org.scribe.http.*" %>
<%@ page import="org.json.*" %>


<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
	<title>Meetup Now</title>
	<link rel="stylesheet" href="css/reset.css" type="text/css" />
	<link rel="stylesheet" href="css/meetupnow.css" type="text/css" />
	<script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>
	<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>

<script type="text/javascript">

	function verifyAddress() {
		var zip = $('#upZip');
		var out = $('#out');
		var geocoder = new google.maps.Geocoder();

		if(geocoder){
			geocoder.geocode( { 'address': zip.val()}, function(results, status) {
				if (status == google.maps.GeocoderStatus.OK) {
					document.getElementById('lat').value = results[0].geometry.location.lat();
					document.getElementById('lon').value = results[0].geometry.location.lng();
					out.empty();
					out.append("VERIFIED");

				} else {
					out.empty();
					out.append("NOT VALID, TRY AGAIN");
				}
			});
		}

	}
</script>
</head>

<%@ include file="jsp/cookie.jsp" %>
<%@ include file="jsp/declares.jsp" %>

<body>
<div id="wrap">
<%@ include file="jsp/header.jsp" %>

		<%
				if (!key.equals("empty")) {

					try {
						users = (List<MeetupUser>) query.execute(key);

						//TRY TO FIND USERINFO DATA
						Query userQuery = pm.newQuery(UserInfo.class);
						userQuery.setFilter("user_id == idParam");
						userQuery.declareParameters("String idParam");
						try {
							List<UserInfo> profiles = (List<UserInfo>) userQuery.execute(users.get(0).getID());
							if (profiles.size() > 0) {
		%>
	<div id="main">	
		<div id="contentRight">
			<div id="contentRightBody">
				<span class="title"><%=users.get(0).getName()%></span>
				<span class="heading">You are receiving notifications from:</span>
				<%
					String[] groups = profiles.get(0).getGroupArray();
					if (groups.length > 0) {
						String apiParam = groups[0];
						for (int i = 1; i < groups.length; i++) {
							apiParam = apiParam + "," + groups[i];
						}
						Token accessToken = new Token(users.get(0).getAccToken(),users.get(0).getAccTokenSecret());
						APIrequest = new Request(Request.Verb.GET, "http://api.meetup.com/ew/containers/?container_id="+apiParam);
						scribe.signRequest(APIrequest,accessToken);
						APIresponse = APIrequest.send();
						JSONObject json = new JSONObject();
						JSONArray results;

	
						try {
							json = new JSONObject(APIresponse.getBody());
							results = json.getJSONArray("results");
							for (int j = 0; j < results.length(); j++) {
				%>
				
				<span class="options"> &nbsp - &nbsp <b><a href="/Topic?<%=results.getJSONObject(j).getString("id")%>"><%=results.getJSONObject(j).getString("urlname") %> </a></b>
				&nbsp <a href="/setprefs?id=<%=users.get(0).getID()%>&callback=UserPrefs.jsp&group=<%=results.getJSONObject(j).getString("id")%>&action=remove">Remove</a> </span>
				<br>
				
				<%
							}
						} catch (JSONException j) {

						}
					}

				%>
			</div> <!-- end #contentRightBody -->
		</div> <!-- end #contentRight -->
		<div id="contentLeft">
			<div id="contentLeftBody">
				<form id="form_userPrefs" name="email" action="/setprefs">
				

				
				<span class="title">Preferences</span>
				

				
				<%
					// Saved Data Persistence
					
					String savedZip = "";
					if(profiles.get(0).getZip() == null) {
						savedZip = "";
					} else {
						savedZip = profiles.get(0).getZip();
					}
					
					String savedRadius = "";
					if(profiles.get(0).getDistance() == null) {
						savedRadius = "";
					} else {
						savedRadius = profiles.get(0).getDistance();
					}
					
					String savedEmail = "";
					if(profiles.get(0).getEmail() == null) {
						savedEmail = "";
					} else {
						savedEmail = profiles.get(0).getEmail();
					}
					
					String savedCellNum = "";
					if(profiles.get(0).getCellNum() == null) {
						savedCellNum = "";
					} else {
						savedCellNum = profiles.get(0).getCellNum();
					}
					
					/*
					String savedCarrier = "";
					if(profiles.get(0).getCarrier() == null) {
						savedCarrier = "-Select-";
					} else {
						savedCarrier = profiles.get(0).getCarrier();
					}
					*/
					
					String savedCarrier = profiles.get(0).getCarrier();
					String attSelected = "";
					String tmobileSelected = "";
					String verizonSelected = "";
					String noCarrierSelected = "";
					if (savedCarrier.equals("att")) {
						attSelected = "selected";
					} else if (savedCarrier.equals("verizon")) {
						verizonSelected = "selected";
					} else if (savedCarrier.equals("tmobile")) {
						tmobileSelected = "selected";
					} else {
						noCarrierSelected = "selected";
					}
				%>
				
				<fieldset>
				<legend>Default Search Area</legend>
					<ul>
					<li>
					<label for="upZip">Zip Code</label>
					<input type="text" class="text" id="upZip" name="zip" value="<%=savedZip%>">
					<input type="button" value="Verify" onclick="verifyAddress()" />
					<div id="out"> </div>
					</li>
					<li>
					<label for="upSearchDistance">Radius (mi)</label>
					<input type="text" class="text" id="upSearchDistance" name="distance" value="<%= savedRadius %>">
					</li>
					</ul>
				</fieldset>

				<fieldset>
				<legend>Receive Email Notifications</legend>
					<ul>
					<li>
					<input type="radio" name="emailOpt" value="yes"> Yes
					<input type="radio" name="emailOpt" value="no" checked> No
					</li>
					<li>
					<label for="upNotificationEmail">Email Address</label>
					<input type="text" class="text" id="upNotificationEmail" name="email" value="<%= savedEmail %>">
					</li>
					</ul>
				</fieldset>
				
				<fieldset>
				<legend>Receive SMS Text Notifications</legend>
					<ul>
					<li>
					<input type="radio" name="cellOpt" value="yes"> Yes
					<input type="radio" name="cellOpt" value="no" checked> No
					</li>
					<li>
					<input type="text" name="cell" value="<%= savedCellNum %>" size="11" /> Cell Number
					</li>
					<li>
					<select name="carrier">
						<option value="" <%=noCarrierSelected%>>-Select-</option>
						<option value="att" <%=attSelected%>>AT&T</option>
						<option value="verizon" <%=verizonSelected%>>Verizon</option>
						<option value="tmobile" <%=tmobileSelected%>>T-Mobile</option>
					</select> Carrier
					</li>
					</ul>
				</fieldset>
				
				<fieldset class="noborder">
					<input type="hidden" name="id" value="<%= users.get(0).getID()%>">
					<input type="hidden" name="callback" value="/UserPrefs.jsp">
					<input type="hidden" id="lat" name="lat" value="NA"/>
					<input type="hidden" id="lon" name="lon" value="NA"/>
					<input type="submit" class="submit" value="Update"></input>
				</fieldset>
				</form>
				

<%
					}
				} finally {
					userQuery.closeAll();
				}
			} finally {
				query.closeAll();
			}
		}
%>

			</div><!-- contentLeftBody -->
		</div><!-- contentLeft -->
	</div> <!-- end #main -->
</div><!-- wrap -->	

<%@ include file="jsp/footer.jsp" %>

</body>
</html>
