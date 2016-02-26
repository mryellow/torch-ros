local xlua = require 'xlua' -- string.split
local ffi = require 'ffi'

local ros = {}
ros.std = {}
ros.tf = {}

local ROS_VER
local rospack_path_cache = {}

-- Assert availability of rospack.
-- Throws an error if rospack cannot be executed, for example because ROS is
-- not installed or the binary is not in the PATH.
local asserted_rospack = false
function assert_rospack()
  if not asserted_rospack then
    local rv = os.execute("rospack 2>/dev/null")
    assert(rv == 0, "Cannot find rospack command, must be in PATH")
    asserted_rospack = true
 end
end

-- Get ROS version
function ros.version()
  if not ROS_VER then
    assert_rospack()
    local p = io.popen("rosversion roscpp 2>/dev/null")
    local version = p:read("*l")
    p:close()
    
    if not version or #version == 0 then
      error("Cannot determine ROS version")
    end
    
    local p = io.popen("rosversion -d 2>/dev/null")
    local codename = p:read("*l")
    p:close()
    
    local v = string.split(version, "%.")
    ROS_VER = {
      version = { tonumber(v[1]), tonumber(v[2]), tonumber(v[3]) },
      codename = codename
    }
 end
 return ROS_VER
end

-- Get path for a package
-- Uses rospack to find the path to a certain package. The path is cached so
-- that consecutive calls will not trigger another rospack execution, but are
-- rather handled directly from the cache. An error is thrown if the package
-- cannot be found.
-- @return path to give package
function ros.find_package(package)
  if not rospack_path_cache[package] then
    local p = io.popen("rospack find " .. package .. " 2>/dev/null")
    rospack_path_cache[package] = p:read("*l")
    p:close()
  end

  assert(rospack_path_cache[package] and #rospack_path_cache[package] > 0, 
    "Package path could not be found for " .. package)
  return rospack_path_cache[package]
end

-- std
local std_cdef = [[
typedef struct std_string {} std_string;
typedef struct std_StringVector {} std_StringVector;

std_string* std_string_new(const char *s, size_t len);
void std_string_delete(std_string *self);
std_string* std_string_clone(std_string *self);
void std_string_assign(std_string *self, const char *s, size_t len);
int std_string_length(std_string *self);
const char* std_string_c_str(std_string *self);

std_StringVector *std_StringVector_new();
std_StringVector *std_StringVector_clone(std_StringVector *self);
void std_StringVector_delete(std_StringVector *ptr);
int std_StringVector_size(std_StringVector *self);
const char* std_StringVector_getAt(std_StringVector *self, size_t pos);
void std_StringVector_setAt(std_StringVector *self, size_t pos, const char *value);
void std_StringVector_push_back(std_StringVector *self, const char *value);
void std_StringVector_pop_back(std_StringVector *self);
void std_StringVector_clear(std_StringVector *self);
void std_StringVector_insert(std_StringVector *self, size_t pos, size_t n, const char *value);
void std_StringVector_erase(std_StringVector *self, size_t begin, size_t end);
bool std_StringVector_empty(std_StringVector *self);
]]

ffi.cdef(std_cdef)

-- ros
local ros_cdef = [[
typedef struct ros_AsyncSpinner {} ros_AsyncSpinner;
typedef struct ros_Time {} ros_Time;
typedef struct ros_Duration {} ros_Duration;

void ros___init(const char *name, uint32_t options);
void ros___shutdown();
void ros___spinOnce();
void ros___requestShutdown();
bool ros___isInitialized();
bool ros___isStarted();
bool ros___isShuttingDown();
bool ros___ok();
void ros___waitForShutdown();

ros_AsyncSpinner* ros_AsyncSpinner_new(uint32_t thread_count);
void ros_AsyncSpinner_delete(ros_AsyncSpinner *self);
bool ros_AsyncSpinner_canStart(ros_AsyncSpinner *self);
void ros_AsyncSpinner_start(ros_AsyncSpinner *self);
void ros_AsyncSpinner_stop(ros_AsyncSpinner *self);

ros_Time* ros_Time_new();
void ros_Time_delete(ros_Time *self);
ros_Time* ros_Time_clone(ros_Time *self);
bool ros_Time_isZero(ros_Time *self);
void ros_Time_fromSec(ros_Time *self, double t);
double ros_Time_toSec(ros_Time *self);
void ros_Time_set(ros_Time *self, unsigned int sec, unsigned int nsec);
void ros_Time_assign(ros_Time *self, ros_Time *other);
int ros_Time_get_sec(ros_Time *self);
void ros_Time_set_sec(ros_Time *self, unsigned int sec);
int ros_Time_get_nsec(ros_Time *self);
void ros_Time_set_nesc(ros_Time *self, unsigned int nsec);
bool ros_Time_lt(ros_Time *self, ros_Time *other);
bool ros_Time_eq(ros_Time *self, ros_Time *other);
void ros_Time_add_Duration(ros_Time *self, ros_Duration *duration, ros_Time *result);
void ros_Time_sub(ros_Time *self, ros_Time *other, ros_Duration *result);
void ros_Time_sub_Duration(ros_Time *self, ros_Duration *duration, ros_Time *result);
void ros_Time_sleepUntil(ros_Time *end);
void ros_Time_getNow(ros_Time *result);
void ros_Time_setNow(ros_Time* now);
void ros_Time_waitForValid();
void ros_Time_init();
void ros_Time_shutdown();
bool ros_Time_useSystemTime();
bool ros_Time_isSimTime();
bool ros_Time_isSystemTime();
bool ros_Time_isValid();

ros_Duration* ros_Duration_new();
void ros_Duration_delete(ros_Duration *self);
ros_Duration* ros_Duration_clone(ros_Duration *self);
void ros_Duration_set(ros_Duration *self, int sec, int nsec);
void ros_Duration_assign(ros_Duration *self, ros_Duration *other);
int ros_Duration_get_sec(ros_Duration *self);
void ros_Duration_set_sec(ros_Duration *self, int sec);
int ros_Duration_get_nsec(ros_Duration *self);
void ros_Duration_set_nsec(ros_Duration *self, int nsec);
void ros_Duration_add(ros_Duration *self, ros_Duration *other, ros_Duration *result);
void ros_Duration_sub(ros_Duration *self, ros_Duration *other, ros_Duration *result);
void ros_Duration_mul(ros_Duration *self, double scale, ros_Duration *result);
bool ros_Duration_eq(ros_Duration *self, ros_Duration *other);
bool ros_Duration_lt(ros_Duration *self, ros_Duration *other);
double ros_Duration_toSec(ros_Duration *self);
void ros_Duration_fromSec(ros_Duration *self, double t);
bool ros_Duration_isZero(ros_Duration *self);
void ros_Duration_sleep(ros_Duration *self);
]]

ffi.cdef(ros_cdef)

-- tf
local tf_cdef = [[
typedef struct tf_Transform {} tf_Transform;
typedef struct tf_StampedTransform {} tf_StampedTransform;
typedef struct tf_Quaternion {} tf_Quaternion;
typedef struct tf_TransformBroadcaster {} tf_TransformBroadcaster;
typedef struct tf_TransformListener {} tf_TransformListener;

tf_Quaternion * tf_Quaternion_new();
tf_Quaternion * tf_Quaternion_clone(tf_Quaternion *self);
void tf_Quaternion_delete(tf_Quaternion *self);
void tf_Quaternion_setIdentity(tf_Quaternion *self);
void tf_Quaternion_setRotation_Tensor(tf_Quaternion *self, THDoubleTensor *axis, double angle);
void tf_Quaternion_setEuler(tf_Quaternion *self, double yaw, double pitch, double roll);
void tf_Quaternion_getRPY(tf_Quaternion *self, int solution_number, THDoubleTensor *result);
void tf_Quaternion_setRPY(tf_Quaternion *self, double roll, double pitch, double yaw);
void tf_Quaternion_setEulerZYX(tf_Quaternion *self, double yaw, double pitch, double roll);
double tf_Quaternion_getAngle(tf_Quaternion *self);
void tf_Quaternion_getAxis_Tensor(tf_Quaternion *self, THDoubleTensor *axis);
void tf_Quaternion_inverse(tf_Quaternion *self, tf_Quaternion *result);
double tf_Quaternion_length2(tf_Quaternion *self);
void tf_Quaternion_normalize(tf_Quaternion *self);
double tf_Quaternion_angle(tf_Quaternion *self, tf_Quaternion *other);
double tf_Quaternion_angleShortestPath(tf_Quaternion *self, tf_Quaternion *other);
void tf_Quaternion_add(tf_Quaternion *self, tf_Quaternion *other, tf_Quaternion *result);
void tf_Quaternion_sub(tf_Quaternion *self, tf_Quaternion *other, tf_Quaternion *result);
void tf_Quaternion_mul(tf_Quaternion *self, tf_Quaternion *other, tf_Quaternion *result);
void tf_Quaternion_mul_scalar(tf_Quaternion *self, double factor, tf_Quaternion *result);
void tf_Quaternion_div_scalar(tf_Quaternion *self, double divisor, tf_Quaternion *result);
double tf_Quaternion_dot(tf_Quaternion *self, tf_Quaternion *other);
void tf_Quaternion_slerp(tf_Quaternion *self, tf_Quaternion *other, double t, tf_Quaternion *result);
void tf_Quaternion_viewTensor(tf_Quaternion *self, THDoubleTensor* result);

tf_Transform *tf_Transform_new();
tf_Transform *tf_Transform_clone(tf_Transform *self);
void tf_Transform_delete(tf_Transform *self);
void tf_Transform_setIdentity(tf_Transform *self);
void tf_Transform_mul_Quaternion(tf_Transform *self, tf_Quaternion *rot, tf_Quaternion *result);
void tf_Transform_mul_Transform(tf_Transform *self, tf_Transform *other, tf_Transform *result);
void tf_Transform_inverse(tf_Transform *self, tf_Transform *result);
void tf_Transform_getBasis(tf_Transform *self, THDoubleTensor *basis);
void tf_Transform_getOrigin(tf_Transform *self, THDoubleTensor *origin);
void tf_Transform_setRotation(tf_Transform *self, tf_Quaternion *rotation);
void tf_Transform_getRotation(tf_Transform *self, tf_Quaternion *rotation);

tf_StampedTransform *tf_StampedTransform_new(tf_Transform *transform, ros_Time* timestamp, const char *frame_id, const char *child_frame_id);
tf_StampedTransform *tf_StampedTransform_clone(tf_StampedTransform *self);
void tf_StampedTransform_delete(tf_StampedTransform *self);
tf_Transform *tf_StampedTransform_getBasePointer(tf_StampedTransform *self);
void tf_StampedTransform_get_stamp(tf_StampedTransform *self, ros_Time *result);
void tf_StampedTransform_set_stamp(tf_StampedTransform *self, ros_Time *stamp);
const char *tf_StampedTransform_get_frame_id(tf_StampedTransform *self);
void tf_StampedTransform_set_frame_id(tf_StampedTransform *self, const char *id);
const char *tf_StampedTransform_get_child_frame_id(tf_StampedTransform *self);
void tf_StampedTransform_set_child_frame_id(tf_StampedTransform *self, const char *id);
void tf_StampedTransform_setData(tf_StampedTransform *self, tf_Transform *input);
bool tf_StampedTransform_eq(tf_StampedTransform *self, tf_StampedTransform *other);

tf_TransformBroadcaster *tf_TransformBroadcaster_new();
void tf_TransformBroadcaster_delete(tf_TransformBroadcaster *self);
void tf_TransformBroadcaster_sendTransform(tf_TransformBroadcaster *self, tf_StampedTransform *transform);

tf_TransformListener * tf_TransformListener_new();
void tf_TransformListener_delete(tf_TransformListener *self);
void tf_TransformListener_clear(tf_TransformListener *self);
void tf_TransformListener_getFrameStrings(tf_TransformListener *self, std_StringVector *result);
void tf_TransformListener_lookupTransform(tf_TransformListener *self, const char *target_frame, const char *source_frame, ros_Time *time, tf_StampedTransform *result);
bool tf_TransformListener_waitForTransform(tf_TransformListener *self, const char *target_frame, const char *source_frame, ros_Time *time, ros_Duration *timeout, std_string *error_msg);
bool tf_TransformListener_canTransform(tf_TransformListener *self, const char *target_frame, const char *source_frame, ros_Time *time);
void tf_TransformListener_lookupTransformFull(tf_TransformListener *self, const char *target_frame, ros_Time *target_time, const char *source_frame, ros_Time *source_time,const char *fixed_frame, tf_StampedTransform *result);
bool tf_TransformListener_waitForTransformFull(tf_TransformListener *self, const char *target_frame, ros_Time *target_time, const char *source_frame, ros_Time *source_time, const char *fixed_frame, ros_Duration *timeout, std_string *error_msg);
bool tf_TransformListener_canTransformFull(tf_TransformListener *self, const char *target_frame, ros_Time *target_time, const char *source_frame, ros_Time *source_time, const char *fixed_frame);
void tf_TransformListener_resolve(tf_TransformListener *self, const char *frame_name, std_string *result);
int tf_TransformListener_getLatestCommonTime(tf_TransformListener *self, const char *source_frame, const char *target_frame, ros_Time *time, std_string* error_string);
void tf_TransformListener_chainAsVector(tf_TransformListener *self, const char *target_frame, ros_Time *target_time, const char *source_frame, ros_Time *source_time, const char *fixed_frame, std_StringVector *result);
bool tf_TransformListener_getParent(tf_TransformListener *self, const char* frame_id, ros_Time *time, std_string *result);
bool tf_TransformListener_frameExists(tf_TransformListener *self, const char *frame_id);
void tf_TransformListener_getCacheLength(tf_TransformListener *self, ros_Duration *result);
void tf_TransformListener_getTFPrefix(tf_TransformListener *self, std_string *result);
]]

ffi.cdef(tf_cdef)

ros.lib = ffi.load(package.searchpath('libtorch-ros', package.cpath))

return ros