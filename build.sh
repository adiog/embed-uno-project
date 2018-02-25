#!/bin/bash

cd $(dirname $0)

PROJECT_NAME=uno-project

ARDUINO_CORE_PATH=./arduino/std/cores/arduino
ARDUINO_VARIANT_PATH=./arduino/std/variants/standard

DEFAULT_DEVICE=`ls -1 /dev/ttyACM* | head -1`
DEVICE=${1:-${DEFAULT_DEVICE}}
[[ -z "${DEVICE}" ]] && echo "Device not found." && exit 1

TOOL_DIR=${ARDUINO_SDK_PATH}/bin

BUILD_DIR=./build
SOURCE_DIR=./${PROJECT_NAME}

CPP=./src/${PROJECT_NAME}.cpp
ELF=${BUILD_DIR}/${PROJECT_NAME}.elf
HEX=${BUILD_DIR}/${PROJECT_NAME}.hex
EEP=${BUILD_DIR}/${PROJECT_NAME}.eep

AVR_CORE=${BUILD_DIR}/libArduino.a

AUTODETECT_SOURCES=`find ${SOURCE_DIR} -name "*.c" -or -name "*.cpp" -or -name "*.cc"` $CPP
AUTODETECT_HEADERS=`find ${SOURCE_DIR} -name "*.h"`

export PATH=${TOOL_DIR}:$PATH

mkdir -p ${BUILD_DIR}

ASM_FLAGS="
    -c                                                           \
    -g                                                           \
    -x assembler-with-cpp                                        \
    -flto                                                        \
    -MMD                                                         \
    -mmcu=atmega328p                                             \
    -DF_CPU=16000000L                                            \
    -DARDUINO=10805                                              \
    -DARDUINO_AVR_UNO                                            \
    -DARDUINO_ARCH_AVR                                           \
    -I${ARDUINO_CORE_PATH}                                       \
    -I${ARDUINO_VARIANT_PATH}"

C_CORE_FLAGS="                                                   \
    -c                                                           \
    -g                                                           \
    -Os                                                          \
    -w                                                           \
    -std=gnu11                                                   \
    -ffunction-sections                                          \
    -fdata-sections                                              \
    -MMD                                                         \
    -flto                                                        \
    -fno-fat-lto-objects                                         \
    -mmcu=atmega328p                                             \
    -DF_CPU=16000000L                                            \
    -DARDUINO=10805                                              \
    -DARDUINO_AVR_UNO                                            \
    -DARDUINO_ARCH_AVR                                           \
    -I${ARDUINO_CORE_PATH}                                       \
    -I${ARDUINO_VARIANT_PATH}"

CXX_CORE_FLAGS="                                                 \
    -c                                                           \
    -g                                                           \
    -Os                                                          \
    -w                                                           \
    -std=gnu++11                                                 \
    -fpermissive                                                 \
    -fno-exceptions                                              \
    -ffunction-sections                                          \
    -fdata-sections                                              \
    -fno-threadsafe-statics                                      \
    -MMD                                                         \
    -flto                                                        \
    -mmcu=atmega328p                                             \
    -DF_CPU=16000000L                                            \
    -DARDUINO=10805                                              \
    -DARDUINO_AVR_UNO                                            \
    -DARDUINO_ARCH_AVR                                           \
    -I${ARDUINO_CORE_PATH}                                       \
    -I${ARDUINO_VARIANT_PATH}"

LD_FLAGS="                                                       \
    -w                                                           \
    -Os                                                          \
    -g                                                           \
    -flto                                                        \
    -fuse-linker-plugin                                          \
    -Wl,--gc-sections                                            \
    -mmcu=atmega328p"

function build_arduino_core_library() {
  mkdir -p ${BUILD_DIR}/core

  avr-gcc ${ASM_FLAGS} ${ARDUINO_CORE_PATH}/wiring_pulse.S -o ${BUILD_DIR}/core/wiring_pulse.S.o

  avr-gcc ${C_CORE_FLAGS} ${ARDUINO_CORE_PATH}/WInterrupts.c -o ${BUILD_DIR}/core/WInterrupts.c.o
  avr-gcc ${C_CORE_FLAGS} ${ARDUINO_CORE_PATH}/hooks.c -o ${BUILD_DIR}/core/hooks.c.o
  avr-gcc ${C_CORE_FLAGS} ${ARDUINO_CORE_PATH}/wiring.c -o ${BUILD_DIR}/core/wiring.c.o
  avr-gcc ${C_CORE_FLAGS} ${ARDUINO_CORE_PATH}/wiring_analog.c -o ${BUILD_DIR}/core/wiring_analog.c.o
  avr-gcc ${C_CORE_FLAGS} ${ARDUINO_CORE_PATH}/wiring_digital.c -o ${BUILD_DIR}/core/wiring_digital.c.o
  avr-gcc ${C_CORE_FLAGS} ${ARDUINO_CORE_PATH}/wiring_pulse.c -o ${BUILD_DIR}/core/wiring_pulse.c.o
  avr-gcc ${C_CORE_FLAGS} ${ARDUINO_CORE_PATH}/wiring_shift.c -o ${BUILD_DIR}/core/wiring_shift.c.o

  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/CDC.cpp -o ${BUILD_DIR}/core/CDC.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/HardwareSerial.cpp -o ${BUILD_DIR}/core/HardwareSerial.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/HardwareSerial0.cpp -o ${BUILD_DIR}/core/HardwareSerial0.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/HardwareSerial1.cpp -o ${BUILD_DIR}/core/HardwareSerial1.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/HardwareSerial2.cpp -o ${BUILD_DIR}/core/HardwareSerial2.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/HardwareSerial3.cpp -o ${BUILD_DIR}/core/HardwareSerial3.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/IPAddress.cpp -o ${BUILD_DIR}/core/IPAddress.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/PluggableUSB.cpp -o ${BUILD_DIR}/core/PluggableUSB.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/Print.cpp -o ${BUILD_DIR}/core/Print.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/Stream.cpp -o ${BUILD_DIR}/core/Stream.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/Tone.cpp -o ${BUILD_DIR}/core/Tone.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/USBCore.cpp -o ${BUILD_DIR}/core/USBCore.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/WMath.cpp -o ${BUILD_DIR}/core/WMath.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/WString.cpp -o ${BUILD_DIR}/core/WString.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/abi.cpp -o ${BUILD_DIR}/core/abi.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/main.cpp -o ${BUILD_DIR}/core/main.cpp.o
  avr-g++ ${CXX_CORE_FLAGS} ${ARDUINO_CORE_PATH}/new.cpp -o ${BUILD_DIR}/core/new.cpp.o

  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/wiring_pulse.S.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/WInterrupts.c.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/hooks.c.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/wiring.c.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/wiring_analog.c.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/wiring_digital.c.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/wiring_pulse.c.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/wiring_shift.c.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/CDC.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/HardwareSerial.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/HardwareSerial0.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/HardwareSerial1.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/HardwareSerial2.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/HardwareSerial3.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/IPAddress.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/PluggableUSB.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/Print.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/Stream.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/Tone.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/USBCore.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/WMath.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/WString.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/abi.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/main.cpp.o
  avr-gcc-ar rcs ${AVR_CORE} ${BUILD_DIR}/core/new.cpp.o
}

echo "Building Arduino Core Library.."
[[ -e ${AVR_CORE} ]] \
  && echo "Using cached Arduino Core Library.."
  || build_arduino_core_library

echo "Compiling project.."
for source in ${AUTODETECT_SOURCES};
do
  avr-g++ ${CXX_CORE_FLAGS} ${source} -o ${BUILD_DIR}/$(basename ${source}).o

echo "Linking project.."
avr-gcc ${LD_FLAGS} -o ${ELF} ${AVR_CORE} -L./build -lm

echo "Building elf.."
avr-objcopy -O ihex -j .eeprom --set-section-flags=.eeprom=alloc,load --no-change-warnings --change-section-lma .eeprom=0 ${ELF} ${EEP}
avr-objcopy -O ihex -R .eeprom ${ELF} ${HEX}
avr-size -A ${ELF}

echo "Flashing.."
avrdude -C${ARDUINO_SDK_PATH}/etc/avrdude.conf -q -q -patmega328p -carduino -P${DEVICE} -b115200 -D -Uflash:w:${HEX}:i

