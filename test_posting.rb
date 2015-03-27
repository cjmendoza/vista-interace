require './server'
require './database'
require "net/http"
require "uri"
require "net/https"
require 'json'
require 'logger'

class TestPosting < Server
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

  test_msg1 = "MSH|^~\&|vista|vista|Vidaguard^Vidaguard|Vidaguard^Vidaguard|20150326155359||ORU^R01|02018301|P|2.3|||AL|NE||||||
PID|1|15-085-0409|15-085-0409||MICkey7^DONALD||199303030000|M|||132^^Clermont^FL^34711^U.S.A.||123||||||321654987|||||||||||N|||||1234547|
ZCP|Height (Feet)||Height (Inches)||Relationship||UMRBMI^BMI||Body Fat||Waist Inches||Hip Inches||Weight||SBP||DBP||VGEMAIL^Vidaguard Email|jafsb@vidaguard.com|VIDAID^Vidaguard ID||Mileage||||
PV1|1|I|^^^Orchard Test Location&loc2503||||33333333^TEMP^DOC||||||||||||1085152839|||||||||||||||||||||||||20150326150300||||||V1508503959|||
ORC|RE||SRU15-02275-1|1|||^^^20150326150300||20150326150300|2009112-0033^Davenport^Keith||33333333^TEMP^DOC|^^^Orchard Test Location&loc2503|||||||1||||
OBR|1||SRU15-02275-1|RUC5555^Reflex Urine Cytology|R||20150326150300|||2009112-0033^Davenport^Keith||||20150326150600|FLUID|33333333^TEMP^DOC||||||20150326155300||vista|F||^^^^^R||^V1508503959|||||kdavenport||||||||||||||||location1^VIDAGUARD|||||INSURANCE|||||OBX|1|ST|APResult^^vista^^^LN||AP results||||||F|||20150326150300|vista|kdavenport||||||||||
NTE|1|| |||
NTE|2||------------------------------------------------------------|||
NTE|3||URINE SEDIMENT CYTOPATHOLOGY REPORT|||
NTE|4||------------------------------------------------------------|||
NTE|5||Final Diagnosis:|||
NTE|6||     Negative for Malignancy.|||
NTE|7||------------------------------------------------------------|||
NTE|8|| |||
NTE|9||Gross Description:  Urine received 20 ml of yellow fluid; 1 ThinPrep slide prepared.|||
NTE|10|| |||
NTE|11||Specimen Adequacy:  Satisfactory.|||
NTE|12|| |||
NTE|13||     Davenport, Keith , , electronically signed 3/26/2015|||
OBX|2|ST|PDFReport^^vista^^^LN||Attachment||||||F||||vista|kdavenport||||||||||
ORC|RE||1085152839|2|||^^^20150326150300||20150326150300|2009112-0033^Davenport^Keith||33333333^TEMP^DOC|^^^Orchard Test Location&loc2503|||||||1||||
OBR|1||1085152839|VG032^Urinalysis (Microscopy w/Reflex)|R||20150326150300|||2009112-0033^Davenport^Keith||||20150326150400|urine|33333333 ^TEMP^DOC||||||20150326150600||vista|F||^^^^^R||^V1508503959|||||kdavenport||||||||||||||||location1^VIDAGUARD|||||INSURANCE|||||
OBX|1|ST|U. COLOR^U. COLOR^vista^^^LN||Straw||Straw - Yellow||||F|||20150326150300|vista|kdavenport||||||||||OBX|2|ST|U. CLARITY^U. CLARITY^vista^^^LN||Clear||Clear||||F|||20150326150300|vista|kdavenport||||||||||
OBX|3|NM|U. SP GRAV^U. SP GRAV^vista^^^LN||1.005||1.010 - 1.030|A|||F|||20150326150300|vista|kdavenport||||||||||
OBX|4|NM|U. PH^U. PH^vista^^^LN||6.0||5.0-8.0||||F|||20150326150300|vista|kdavenport||||||||||OBX|5|ST|U. LEU^U. LEU^vista^^^LN||Negative||Negative||||F|||20150326150300|vista|kdavenport||||||||||
OBX|6|ST|U. NITRITE^U. NITRITE^vista^^^LN||Positive||Negative|A|||F|||20150326150300|vista|kdavenport||||||||||
OBX|7|ST|U. PROTEIN^U. PROTEIN^vista^^^LN||1+|mg/dL|Negative|A|||F|||20150326150300|vista|kdavenport||||||||||
OBX|8|ST|U. GLUCOSE^U. GLUCOSE^vista^^^LN||1+|mg/dL|Negative|A|||F|||20150326150300|vista|kdavenport||||||||||
OBX|9|ST|U. KETONES^U. KETONES^vista^^^LN||1+|mg/dL|Negative|A|||F|||20150326150300|vista|kdavenport||||||||||
OBX|10|NM|U. UROBILI^U. UROBILI^vista^^^LN||0.2|mg/dL|0.2 - 1.0||||F|||20150326150300|vista|kdavenport||||||||||
OBX|11|ST|U. BILI^U. BILI^vista^^^LN||1+||Negative|A|||F|||20150326150300|vista|kdavenport||||||||||
OBX|12|ST|U. BLOOD^U. BLOOD^vista^^^LN||3+||Negative|A|||F|||20150326150300|vista|kdavenport||||||||||
OBX|13|ST|U. WBC^U. WBC^vista^^^LN||50-100|/HPF|NONE SEEN;0-5|A|||F|||20150326150300|vista|kdavenport||||||||||
OBX|14|ST|U. RBC^U. RBC^vista^^^LN||0-2|/HPF|0-2||||F|||20150326150300|vista|kdavenport||||||||||OBX|15|ST|U. EPI^U. EPI^vista^^^LN||0-5|/HPF|||||F|||20150326150300|vista|kdavenport||||||||||
OBX|16|ST|U. BACTERIA^U. BACTERIA^vista^^^LN||Negative||Negative||||F|||20150326150300|vista|kdavenport||||||||||
OBX|17|ST|U. CASTS^U. CASTS^vista^^^LN||Absent|/HPF|Absent||||F|||20150326150300|vista|kdavenport||||||||||
OBX|18|ST|U. CRYSTALS^U. CRYSTALS^vista^^^LN||Negative||Negative||||F|||20150326150300|vista|kdavenport||||||||||
OBX|19|ST|U. MUCUS^U. MUCUS^vista^^^LN||Negative||Negative||||F|||20150326150300|vista|kdavenport||||||||||OBX|20|ST|U. TRICH^U. TRICH^vista^^^LN||Negative||Negative||||F|||20150326150300|vista|kdavenport||||||||||
OBX|21|ST|U. SPERM^U. SPERM^vista^^^LN||Negative||Negative||||F|||20150326150300|vista|kdavenport||||||||||
OBX|22|ST|U. YEAST^U. YEAST^vista^^^LN||Few||Negative|A|||F|||20150326150300|vista|kdavenport||||||||||
ORC|RE||1085152839|3|||^^^20150326150300||20150326150300|2009112-0033^Davenport^Keith||33333333^TEMP^DOC|^^^Orchard Test Location&loc2503|||||||1||||
OBR|1||1085152839|VG031^Urine Culture|R||20150326150300|||2009112-0033^Davenport^Keith||||20150326150400|urine|33333333^TEMP^DOC||||||20150326152100||vista|F||^^^^^R||^V1508503959|||||||||||||||||||||location1^VIDAGUARD|||||INSURANCE|||||
NTE|1||Type of collection? : Clean Catch|SU||OBX|1|ST|PRELIM REPORT^PRELIM REPORT^vista^^^LN||Microbiology results||||||P|||20150326150300|vista|||||||||||
NTE|1||SITE:|||
NTE|2||Clean Catch|||
NTE|3|||||
NTE|4||RESULT|||
NTE|5||nO gROWTH|||
OBX|2|ST|FINAL REPORT^FINAL REPORT^vista^^^LN||Microbiology results||||||F|||20150326150300|vista|kdavenport||||||||||NTE|1||SITE:|||
NTE|2||Clean Catch|||
NTE|3|||||
NTE|4||RESULT|||
NTE|5||nO gROWTH|||
NTE|6|||||
NTE|7||Result 2|||
NTE|8||No Growth|||"

  DEVEL = 'http://release.vidaguard.com:3001'
  PRODUCTION = 'http://127.0.0.1'

  def initialize
    @logger = Logger.new $stdout
    @logger.level = Logger::DEBUG
    @dbh = Database.connect(@logger)
    rows = @dbh.query("select * from interfaces where name = 'vista_orchard'")
    rows.each_hash do |rv| #should be only one row
      @interface_id = rv['id']
    end
  end

  serv = self.new
  puts "Posting results #{serv.post_results('111111', test_msg1, DEVEL)}"
  #puts "Posting old results #{serv.post_old_results(DEVEL)}"

end