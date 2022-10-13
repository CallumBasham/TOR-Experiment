#!/bin/bash

# < Central WAN stemming to Countries - Collision Domains > #----------------------
mkdir AS{1..4}
touch AS{1..4}.startup

mkdir {ru,uk,de,us}_isp
touch {ru,uk,de,us}_isp.startup


# < Rename Dirauths > #----------------------
#US
mv dirauth1.startup us_dirauth1.startup && mv dirauth1 us_dirauth1
mv dirauth2.startup us_dirauth2.startup && mv dirauth2 us_dirauth2
mv dirauth3.startup us_dirauth3.startup && mv dirauth3 us_dirauth3
mv dirauth4.startup us_dirauth4.startup && mv dirauth4 us_dirauth4
mv dirauth5.startup us_dirauth5.startup && mv dirauth5 us_dirauth5
mv dirauth6.startup us_dirauth6.startup && mv dirauth6 us_dirauth6

#UK
mv dirauth7.startup uk_dirauth1.startup && mv dirauth7 uk_dirauth1
mv dirauth8.startup uk_dirauth2.startup && mv dirauth8 uk_dirauth2


#RU
mv dirauth9.startup ru_dirauth1.startup && mv dirauth9 ru_dirauth1


# < Rename Exits > (remmeber up to 12 is exit) #----------------------
#US
mv relay1.startup us_exit1.startup && mv relay1 us_exit1
mv relay2.startup us_exit2.startup && mv relay2 us_exit2
mv relay3.startup us_exit3.startup && mv relay3 us_exit3

#UK
mv relay4.startup uk_exit1.startup && mv relay4 uk_exit1
mv relay5.startup uk_exit2.startup && mv relay5 uk_exit2
mv relay6.startup uk_exit3.startup && mv relay6 uk_exit3

#RU
mv relay7.startup ru_exit1.startup && mv relay7 ru_exit1
mv relay8.startup ru_exit2.startup && mv relay8 ru_exit2
mv relay9.startup ru_exit3.startup && mv relay9 ru_exit3

#DE
mv relay10.startup de_exit1.startup && mv relay10 de_exit1
mv relay11.startup de_exit2.startup && mv relay11 de_exit2
mv relay12.startup de_exit3.startup && mv relay12 de_exit3


# < Rename Relays > (remmeber up to 36 is relay) #----------------------
#US
mv relay13.startup us_relay1.startup && mv relay13 us_relay1
mv relay14.startup us_relay2.startup && mv relay14 us_relay2
mv relay15.startup us_relay3.startup && mv relay15 us_relay3
mv relay16.startup us_relay4.startup && mv relay16 us_relay4
mv relay17.startup us_relay5.startup && mv relay17 us_relay5
mv relay18.startup us_relay6.startup && mv relay18 us_relay6

#UK
mv relay19.startup uk_relay1.startup && mv relay19 uk_relay1
mv relay20.startup uk_relay2.startup && mv relay20 uk_relay2
mv relay21.startup uk_relay3.startup && mv relay21 uk_relay3
mv relay22.startup uk_relay4.startup && mv relay22 uk_relay4
mv relay23.startup uk_relay5.startup && mv relay23 uk_relay5
mv relay24.startup uk_relay6.startup && mv relay24 uk_relay6

#RU
mv relay25.startup ru_relay1.startup && mv relay25 ru_relay1
mv relay26.startup ru_relay2.startup && mv relay26 ru_relay2
mv relay27.startup ru_relay3.startup && mv relay27 ru_relay3
mv relay28.startup ru_relay4.startup && mv relay28 ru_relay4
mv relay29.startup ru_relay5.startup && mv relay29 ru_relay5
mv relay30.startup ru_relay6.startup && mv relay30 ru_relay6

#DE
mv relay31.startup de_relay1.startup && mv relay31 de_relay1
mv relay32.startup de_relay2.startup && mv relay32 de_relay2
mv relay33.startup de_relay3.startup && mv relay33 de_relay3
mv relay34.startup de_relay4.startup && mv relay34 de_relay4
mv relay35.startup de_relay5.startup && mv relay35 de_relay5
mv relay36.startup de_relay6.startup && mv relay36 de_relay6


# < Rename Web Server & Router > #----------------------
#US
cp router3.startup us_rt_web.startup && mkdir us_rt_web
cp router2.startup us_rt_cli.startup && mkdir us_rt_cli
cp websrv.startup us_websrv.startup && mkdir us_websrv
cp client.startup us_client.startup && cp -r client us_client

#UK
cp router3.startup uk_rt_web.startup && mkdir uk_rt_web
cp router2.startup uk_rt_cli.startup && mkdir uk_rt_cli
cp websrv.startup uk_websrv.startup && mkdir uk_websrv
cp client.startup uk_client.startup && cp -r client uk_client

#RU
cp router3.startup ru_rt_web.startup && mkdir ru_rt_web
cp router2.startup ru_rt_cli.startup && mkdir ru_rt_cli
cp websrv.startup ru_websrv.startup && mkdir ru_websrv
cp client.startup ru_client.startup && cp -r client ru_client

#DE
cp router3.startup de_rt_web.startup && mkdir de_rt_web
cp router2.startup de_rt_cli.startup && mkdir de_rt_cli
cp websrv.startup de_websrv.startup && mkdir de_websrv
cp client.startup de_client.startup && cp -r client de_client

# Cleanup
rm -rf router{1..3} && rm router{1..3}.startup
rm -rf client && rm client.startup
rm -rf websrv && rm websrv.startup


