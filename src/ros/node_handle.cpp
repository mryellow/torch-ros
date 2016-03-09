#include "torch-ros.h"
#include "message_buffer.h"

ROSIMP(ros::NodeHandle *, NodeHandle, new)() {
  return new ros::NodeHandle();
}

ROSIMP(void, NodeHandle, delete)(ros::NodeHandle *self) {
  delete self;
}

ROSIMP(ros::Subscriber *, NodeHandle, subscribe)(
  ros::NodeHandle *self,
  boost::shared_ptr<MessageBuffer> *message_buffer,
  const char *topic,
  unsigned int queue_size,
  const char *md5sum,
  const char *datatype
) {
  ros::SubscribeOptions so(topic, queue_size, md5sum, datatype);
  so.helper = *message_buffer;
  return new ros::Subscriber(self->subscribe(so));
}

ROSIMP(ros::Publisher *, NodeHandle, advertise)(
  ros::NodeHandle *self,
  const char *topic,
  unsigned int queue_size,
  const char *md5sum,
  const char *datatype,
  const char *message_definition
) {
  ros::AdvertiseOptions ao(topic, queue_size, datatype, message_definition);
  return new ros::Publisher(self->advertise(ao));
}
