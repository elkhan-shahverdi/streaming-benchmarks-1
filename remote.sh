#!/usr/bin/env bash

rm ./nohup.out
TEST_TIME=1800
TPS="1000"
BATCH="2000"
SHORT_SLEEP=10
LONG_SLEEP=20
WAIT_AFTER_STOP_PRODUCER=120

CLEAN_LOAD_RESULT_CMD="rm stream.*;"
CLEAN_RESULT_CMD="cd stream-benchmarking; rm data/*.txt;"

CLEAN_BUILD_BENCHMARK="cd stream-benchmarking; ./stream-bench.sh SETUP_BENCHMARK"

CHANGE_TPS_CMD="sed -i “s/LOAD:-1000/LOAD:-$TPS/g” stream-benchmarking/stream-bench.sh;"

LOAD_START_CMD="cd stream-benchmarking; ./stream-bench.sh START_LOAD;"
LOAD_STOP_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_LOAD;"

DELETE_TOPIC="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/kafka-topics.sh --delete --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --topic ad-events;"
CREATE_TOPIC="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/kafka-topics.sh --create --zookeeper zookeeper-node01:2181,zookeeper-node02:2181,zookeeper-node03:2181 --replication-factor 1 --partitions 4 --topic ad-events;"

START_MONITOR_PROCESS_CMD="top -b -d 1 | grep --line-buffered java > stream.process;"
STOP_MONITOR_PROCESS_CMD="ps aux | grep top | awk {'print \$2'} | xargs sudo kill;"
MONITOR_PID_CMD="ps aux | grep java > stream.pid"

START_FLINK_CMD="cd stream-benchmarking; ./flink-1.4.0/bin/start-cluster.sh;"
STOP_FLINK_CMD="cd stream-benchmarking; ./flink-1.4.0/bin/stop-cluster.sh;"
START_FLINK_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh START_FLINK_PROCESSING;"
STOP_FLINK_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_FLINK_PROCESSING;"

START_SPARK_CMD="cd stream-benchmarking/spark-2.2.1-bin-hadoop2.6; ./sbin/start-all.sh;"
STOP_SPARK_CMD="cd stream-benchmarking/spark-2.2.1-bin-hadoop2.6; ./sbin/stop-all.sh;"
START_SPARK_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh START_SPARK_PROCESSING;"
STOP_SPARK_PROC_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_SPARK_PROCESSING;"

START_ZK_CMD="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/zookeeper-server-start.sh -daemon config/zookeeper.properties"
STOP_ZK_CMD="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/zookeeper-server-stop.sh;"

START_KAFKA_CMD="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/kafka-server-start.sh -daemon config/server.properties"
STOP_KAFKA_CMD="cd stream-benchmarking/kafka_2.11-0.11.0.2; ./bin/kafka-server-stop.sh;"

START_REDIS_CMD="cd stream-benchmarking; ./stream-bench.sh START_REDIS;"
STOP_REDIS_CMD="cd stream-benchmarking; ./stream-bench.sh STOP_REDIS;"

PULL_GIT="cd stream-benchmarking; git reset --hard HEAD; git pull origin master;"




. ./remoteInvocation.sh --source-only

function pullRepository {
    runCommandStreamServers "${PULL_GIT}" "nohup"
    runCommandZKServers "${PULL_GIT}" "nohup"
    runCommandKafkaServers "${PULL_GIT}" "nohup"
    runCommandLoadServers "${PULL_GIT}" "nohup"
    runCommandRedisServer "${PULL_GIT}" "nohup"
}

function stopLoadData {
    echo "Main loaders stopping"
    runCommandLoadServers "${LOAD_STOP_CMD}" "nohup"
}

function stopZkLoadData {
    echo "Zookeeper loaders stopping"
    runCommandZKServers "${LOAD_STOP_CMD}" "nohup"
}


function startLoadData {
    echo "Main loaders starting"
    runCommandLoadServers "${LOAD_START_CMD}" "nohup"

}

function startZkLoadData {
    echo "Zookeeper loaders starting"
    runCommandZKServers "${LOAD_START_CMD}" "nohup"
}


function cleanKafka {
    echo "Deleted kafka topic"
    runCommandRedisServer "${DELETE_TOPIC}"
    echo "Created kafka topic"
    runCommandRedisServer "${CREATE_TOPIC}"
}

function startZK {
    echo "Starting Zookeepers"
    runCommandZKServers "${START_ZK_CMD}"
}

function stopZK {
    echo "Stopping Zookeepers"
    runCommandZKServers "${STOP_ZK_CMD}"
}


function startKafka {
    echo "Starting Kafka nodes"
    runCommandKafkaServers "${START_KAFKA_CMD}"
}

function stopKafka {
    echo "Stopping Kafka nodes"
    runCommandKafkaServers "${STOP_KAFKA_CMD}"
}

function cleanResult {
    echo "Cleaning previous benchmark result"
    runCommandStreamServers "${CLEAN_LOAD_RESULT_CMD}"
    runCommandKafkaServers "${CLEAN_LOAD_RESULT_CMD}"
    ssh ubuntu@redis ${CLEAN_RESULT_CMD}
}

function startFlink {
    echo "Starting Flink"
    ssh ubuntu@stream-node01 ${START_FLINK_CMD}
}

function stopFlink {
    echo "Stopping Flink"
    ssh ubuntu@stream-node01 ${STOP_FLINK_PROC_CMD}
}

function startFlinkProcessing {
    echo "Starting Flink Processing"
    nohup ssh ubuntu@stream-node01 ${START_FLINK_PROC_CMD} &
}

function stopFlinkProcessing {
    echo "Stopping Flink Processing"
    nohup ssh ubuntu@stream-node01 ${STOP_FLINK_CMD} &
}

function startSpark {
    echo "Starting Spark"
    ssh ubuntu@stream-node01 ${START_SPARK_CMD}
}

function stopSpark {
    echo "Stopping Spark"
    ssh ubuntu@stream-node01 ${STOP_SPARK_CMD}
}

function startSparkProcessing {
    echo "Starting Spark processing"
    nohup ssh ubuntu@stream-node01 ${START_SPARK_PROC_CMD} &
}

function stopSparkProcessing {
    echo "Stopping Spark processing"
    nohup ssh ubuntu@stream-node01 ${STOP_SPARK_PROC_CMD} &
}

function getProcessId(){
    runCommandStreamServers "${MONITOR_PID_CMD}"
    runCommandKafkaServers "${MONITOR_PID_CMD}"
}

function startMonitoring(){
    runCommandStreamServers "${START_MONITOR_PROCESS_CMD}" "nohup"
    runCommandKafkaServers "${START_MONITOR_PROCESS_CMD}" "nohup"
}

function stopMonitoring(){
    runCommandStreamServers "${STOP_MONITOR_PROCESS_CMD}"
    runCommandKafkaServers "${STOP_MONITOR_PROCESS_CMD}"
}

function changeTps(){
    runCommandLoadServers "sed -i \"s/LOAD:-1000/LOAD:-$TPS/g\" stream-benchmarking/stream-bench.sh"
    runCommandZKServers "sed -i \"s/LOAD:-1000/LOAD:-$TPS/g\" stream-benchmarking/stream-bench.sh"
}


function startRedis {
    echo "Starting Redis"
    runCommandRedisServer "${START_REDIS_CMD}" "nohup"
    sleep ${SHORT_SLEEP}
}

function stopRedis {
    echo "Stopping Redis"
    runCommandRedisServer "${STOP_REDIS_CMD}"
    sleep ${SHORT_SLEEP}
}


function prepareEnvironment(){
    cleanResult
    startZK
    sleep ${LONG_SLEEP}
    startKafka
    sleep ${LONG_SLEEP}
    cleanKafka
    startRedis
    sleep ${LONG_SLEEP}
}

function destroyEnvironment(){
    sleep ${SHORT_SLEEP}
    stopRedis
    stopKafka
    sleep ${SHORT_SLEEP}
    stopZK
}


function getBenchmarkResult(){

    if [ "$1" == "spark" ]; then
        PATH_RESULT=result/${1}_${BATCH}/TPS_${TPS}_DURATION_${TEST_TIME}
    else
        PATH_RESULT=result/${1}/TPS_${TPS}_DURATION_${TEST_TIME}
    fi
    rm -rf ${PATH_RESULT};
    mkdir ${PATH_RESULT}
    getResultFromStreamServer "${PATH_RESULT}"
    getResultFromKafkaServer "${PATH_RESULT}"
    getResultFromRedisServer "${PATH_RESULT}"

    Rscript reporting.R

}

function benchmark(){
    sleep ${LONG_SLEEP}
    startMonitoring
    startLoadData
    startZkLoadData
    sleep ${TEST_TIME}
    stopZkLoadData
    stopLoadData
    sleep ${LONG_SLEEP}
    stopMonitoring
    sleep ${WAIT_AFTER_STOP_PRODUCER}
    getProcessId

}


function runSystem(){
    prepareEnvironment
    case $1 in
        flink)
            startFlink
            sleep ${SHORT_SLEEP}
            startFlinkProcessing
            benchmark $1
            stopFlinkProcessing
            sleep ${SHORT_SLEEP}
            stopFlink
        ;;
        spark)
            startSpark
            sleep ${SHORT_SLEEP}
            startSparkProcessing
            benchmark $1
            stopSparkProcessing
            sleep ${SHORT_SLEEP}
            stopSpark
        ;;
    esac
    destroyEnvironment
    getBenchmarkResult $1

}

function stopAll (){
    stopZkLoadData
    stopLoadData
    stopMonitoring
    stopFlinkProcessing
    stopFlink
    stopSparkProcessing
    stopSpark
    destroyEnvironment
}


function benchmarkLoop (){
    while true; do
        pullRepository
        sleep ${SHORT_SLEEP}
        if (("$TPS" > "4000")); then
            break
        fi
        changeTps
        runSystem $1
        TPS=$[$TPS + 1000]
    done
}


case $1 in
    flink)
        benchmarkLoop "flink"
    ;;
    spark)
        benchmarkLoop "spark"
    ;;
    all)
        benchmarkLoop "flink"
        benchmarkLoop "spark"
    ;;
    start)
        prepareEnvironment
        startFlink
        startFlinkProcessing
    ;;
    stop)
        stopAll
    ;;
    push)
        git add --all
        git commit -am "Automatic push message"
        git push origin master
        pullRepository
    ;;
    report)
        Rscript reporting.R
    ;;
    build)
        runCommandStreamServers "${CLEAN_BUILD_BENCHMARK}" "nohup"
    ;;
    *)
        echo "Please Enter valid command"
esac

