#ifndef SENSING_H_
#define SENSING_H_

#include <IPDispatch.h>

enum {
  AM_SENSING_REPORT = -1
};

typedef nx_struct settings{
	nx_uint16_t threshold;
	nx_uint32_t sample_time;
	nx_uint32_t sample_period;
} settings_t;

nx_struct sensing_report {
  nx_uint16_t sender;
  nx_uint8_t type;
  settings_t settings;
};

enum{
	SETTING_REQUEST = 1,
	SETTING_RESPONSE = 2,
	SETTING_USER = 4
}

nx_struct theft_report{
	nx_uint16_t who;
}

#define REPORT_DEST "fec0::100"
#define MULTICAST "ff02::1"

#endif
