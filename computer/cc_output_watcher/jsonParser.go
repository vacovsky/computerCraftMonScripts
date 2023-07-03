package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"reflect"
)

func ingestMonitorDataToRedis(filePath string) {
	// Open our jsonFile
	jsonFile, err := os.Open(filePath)
	// if we os.Open returns an error then handle it
	if err != nil {
		fmt.Println(err)
	}
	fmt.Printf("Successfully Opened %s", filePath)
	// defer the closing of our jsonFile so that we can parse it later on
	defer jsonFile.Close()

	byteValue, _ := ioutil.ReadAll(jsonFile)

	var result map[string]interface{}
	json.Unmarshal([]byte(byteValue), &result)

	timeStampF, _ := result["timeStamp"].(float64)
	timeStamp := int64(timeStampF)

	for _, v := range result {
		// if reflect.TypeOf(v) == reflect.TypeOf(reflect.Float64) {
		// 	continue OUTER
		// }
		var dataEncapType map[string]interface{} = nil
		if reflect.TypeOf(v) != reflect.TypeOf(dataEncapType) {
			continue
		}
		device := v.(map[string]interface{})
		for deviceProperty, propertyValue := range device {

			// devicename:method = value
			redisKey := fmt.Sprintf("%s:%s", device["name"], deviceProperty)
			if reflect.TypeOf(propertyValue) == reflect.TypeOf(1) || reflect.TypeOf(propertyValue) == reflect.TypeOf(1.1) {
				propV, _ := propertyValue.(float64)
				redisTsWrite(redisKey, timeStamp, propV)
				log.Printf("Writing %s %d %f", redisKey, timeStamp, propV)
			}
		}
	}

}
