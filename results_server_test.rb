require './server'
require 'mysql'
class ResultsServerTest

  test_msg ="MSH|^~\&|vista|vista|Vidaguard^Vidaguard|Vidaguard^Vidaguard|20150112150249||ORU^R01|00266857|P|2.3|||AL|NE||||||
PID|1||14-041-0504||MOU^MIKK||200101010000|F|MOUSE^MIKK~mouse^mikk~mouse^mikkey~mouse^Mikkey~MOUSE^MIKKEY||2145 Kingsley Ave^^ORANGE PARK^FL^32073||(904)272-2424||||||012345678|||||||||||N|||||10055092|
ZCP|Height (Feet)||Height (Inches)||Relationship||UMRBMI^BMI||Body Fat||Waist Inches||Hip Inches||Weight||SBP||DBP||VGEMAIL^Vidaguard Email|me@me.com|||
PV1|1|O|^^^Orchard Test Location&loc2503||||2014287-0030^MCDADE JR^EDWARD DONALD^^^^MD||||||||||||1012152838|||||||||||||||||||||||||20150112120600||||||V1501203910|||
ORC|RE||1012152838|1|||^^^20150112120600||20150112120600|2009112-0033^Davenport^Keith||2014287-0030^MCDADE JR^EDWARD DONALD^^^^MD|^^^Orchard Test Location&loc2503|||||||1||||
OBR|1||1012152838|VG003^Basic Metabolic Panel with eGFR|R||20150112120600|||2009112-0033^Davenport^Keith||||20150112120800|Serum|2014287-0030^MCDADE JR^EDWARD DONALD^^^^MD||||||20150112120900||vista|F||^^^^^R||^V1501203910|||||kdavenport||||||||||||||||location1^VIDAGUARD|||||INSURANCE|||||
NTE|1||Called Dr|||
OBX|1|NM|GLU^GLU^vista^^^LN||75|mg/dL|70-99||||F|||20150112120600|vista|kdavenport||||||||||
OBX|2|NM|CA^CA^vista^^^LN||15.0|mg/dL|8.6-10.2|HH|||F|||20150112120600|vista|kdavenport||||||||||
OBX|3|NM|BUN^BUN^vista^^^LN||15|mg/dL|6-20||||F|||20150112120600|vista|kdavenport||||||||||
OBX|4|NM|CR^CR^vista^^^LN||0.8|mg/dL|0.5-1.2||||F|||20150112120600|vista|kdavenport||||||||||
OBX|5|NM|BN/CR^BN/CR^vista^^^LN||18.3||6.0-25.0||||F|||20150112120600|vista|kdavenport||||||||||
OBX|6|NM|NA^NA^vista^^^LN||100|mmol/L|136-145|LL|||F|||20150112120600|vista|kdavenport||||||||||
OBX|7|NM|K^K^vista^^^LN||4.0|mmol/L|3.3-5.1||||F|||20150112120600|vista|kdavenport||||||||||
OBX|8|NM|CL^CL^vista^^^LN||100|mmol/L|98-107||||F|||20150112120600|vista|kdavenport||||||||||
OBX|9|NM|CO2^CO2^vista^^^LN||25|mmol/L|22-31||||F|||20150112120600|vista|kdavenport||||||||||
OBX|10|NM|ANGAP^ANGAP^vista^^^LN||-21.0||||||F|||20150112120600|vista|kdavenport||||||||||
OBX|11|NM|ZEGFR^ZEGFR^vista^^^LN||101.5||||||F|||20150112120600|vista|kdavenport||||||||||
NTE|1||Reference Table for Population Mean GFRs from NHANES 1114  Age (Years)         Average GFR   20-29               116 ml/min/1.73m2   30-39               107 ml/min/1.73m2   40-49                99 ml/min/1.73m2   50-59                93 ml/min/1.73m2   60-69                85 ml/min/1.73m2   70+                  75 ml/min/1.73m2|||"

  srv = Server.new('vista_orchard', 37056, '127.0.0.1', true)
  segs = test_msg.split('|')
  #puts srv.prepare_ack(segs, TEST_MSG)
  srv.logger = Logger.new $stdout
  srv.dbh = Mysql.new('localhost', 'root', '', 'careflow')
  srv.interface_id = 1
  srv.post_results(segs[9], test_msg)
end