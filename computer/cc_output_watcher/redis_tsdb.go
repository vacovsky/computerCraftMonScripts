package main

import (
	"fmt"

	redistimeseries "github.com/RedisTimeSeries/redistimeseries-go"
)

var CLIENT *redistimeseries.Client = nil

func init() {
	CLIENT = redistimeseries.NewClient("192.168.111.56:6379", "nohelp", nil)
}

func redisTsWrite(keyName string, timeStamp int64, dataVal float64) {
	// Connect to localhost with no password
	var keyname = "mytest"
	_, haveit := CLIENT.Info(keyname)
	if haveit != nil {
		CLIENT.CreateKeyWithOptions(keyname, redistimeseries.DefaultCreateOptions)
		CLIENT.CreateKeyWithOptions(keyname+"_avg", redistimeseries.DefaultCreateOptions)
		CLIENT.CreateRule(keyname, redistimeseries.AvgAggregation, 60, keyname+"_avg")
	}
	// Add sample with timestamp from server time and value 100
	// TS.ADD mytest * 100
	_, err := CLIENT.Add(keyName, timeStamp, dataVal)
	if err != nil {
		fmt.Println("Error:", err)
	}
}

// func redis_test() {
// 	// Connect to localhost with no password
// 	var keyname = "mytest"
// 	_, haveit := CLIENT.Info(keyname)
// 	if haveit != nil {
// 		CLIENT.CreateKeyWithOptions(keyname, redistimeseries.DefaultCreateOptions)
// 		CLIENT.CreateKeyWithOptions(keyname+"_avg", redistimeseries.DefaultCreateOptions)
// 		CLIENT.CreateRule(keyname, redistimeseries.AvgAggregation, 60, keyname+"_avg")
// 	}
// 	// Add sample with timestamp from server time and value 100
// 	// TS.ADD mytest * 100
// 	_, err := CLIENT.AddAutoTs(keyname, 100)
// 	if err != nil {
// 		fmt.Println("Error:", err)
// 	}
// }
