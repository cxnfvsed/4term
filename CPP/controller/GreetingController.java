package com.example.demo.controller;

import com.example.demo.HashMap.Cache;
import com.example.demo.counter.Counter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;

import java.util.LinkedList;
import java.util.List;

@RestController
public class GreetingController {
   protected Logger logger = LoggerFactory.getLogger(getClass());
    @Autowired
    private Cache cache;

    @GetMapping("/result")
    public Greeting greetingController(@RequestParam(value = "year", defaultValue = "1980") int num) {
        Counter counter = new Counter();
        counter.incCounter();
        if(num<1200){
            String em = "Invalid data";
            logger.error(em);
            throw new HttpClientErrorException(HttpStatus.BAD_REQUEST,em);
        }

        String s = num + " year";
        if(cache.isStored(s))
        {
           logger.info("Restored from cache: " + num);
           return new Greeting(num);
        }

        Greeting obj;
        try{
            obj = new Greeting(num);
            obj.getContent();
        }catch(RuntimeException ex){
            String message = "Computation error";
            logger.error(message);
            throw new HttpServerErrorException(HttpStatus.INTERNAL_SERVER_ERROR,message);
        }

        cache.insert(s,obj.getContent());
        logger.info("Success");
        return obj;
    }

    @PostMapping("/result")
    public ResponseEntity<?> bulkParams(@RequestBody List<IntermediateBody> bodyList) {
        if (bodyList.isEmpty()) {
            return new ResponseEntity<>("400 error!", HttpStatus.BAD_REQUEST);
        }
        List<Greeting> GreetingList = new LinkedList<>();
        for (IntermediateBody tmp : bodyList) {
          try {
                Greeting temper = new Greeting(Integer.parseInt(tmp.getYear().trim()));
                GreetingList.add(temper);
           } catch (Exception e) {
                return new ResponseEntity<>("404 error(String as input).", HttpStatus.BAD_REQUEST);
          }
        }

        AverageValues val = new AverageValues();
        //каждый элемент листа в память
        GreetingList.forEach((greeting) -> {
            String s = greeting.getYear() + " year";
            if(cache.isStored(s)){
                logger.info("Restored from cache: "+ greeting.getYear());
            }
            else{
                greeting.getContent();
                logger.info("Success");
                cache.insert(s, greeting.getContent());
            }
        });
        val.setGreetingAnswerList(GreetingList);
        val.CalcAverage(GreetingList);
        logger.info("Average was calculated!");

        return new ResponseEntity<>(val, HttpStatus.OK);
    }
}






























//        if (y < 1200) {
//            String message = "year " + String.valueOf(y) + " is incorrect";
//            logger.error(message);
//            throw new HttpClientErrorException(HttpStatus.BAD_REQUEST, message);
//        }
//
//        String s = String.valueOf(y) + " year";
//        if (cache.isStored(s)) {
//            logger.info("Value restored from cache: " + String.valueOf(y));
//            return new Greeting(y, cache.get(s));
//        }
//
//        Greeting newObj;
//        try {
//            newObj = new Greeting(y);
//            newObj.getContent();
//        } catch (RuntimeException e) {
//            String errorM = "computing error";
//            logger.error(errorM);
//            throw new HttpServerErrorException(HttpStatus.INTERNAL_SERVER_ERROR, errorM);
//        }
//
//        cache.insert(s, newObj.getContent());
//        logger.info("Successfully computed!");
//        return newObj;















//import com.example.demo.exceptions.ApiRequestException;
//@RestController
//public class GreetingController {
//    Logger logger = (Logger) LoggerFactory.getLogger(GreetingController.class); //logger initialization
//
//    @Autowired
//    public HashMapa hashMapa;
//    //By using this annotation, you don't have to worry about how best to pass an instance of another bean to a class or bean.
//    // The Spring framework itself will find the required bean and place its value into the property marked with the @Autowired annotation.
//
//    @GetMapping("/greeting") // annotation ensures that HTTP GET
//    //requests to /greeting are mapped to the greeting method
//    public Greeting greeting(@RequestParam(value = "year", defaultValue = "1980") int y) {
//        Counter counter = new Counter();
//        counter.incCounter();
//        try { //if the year is less - throws 404 error
//            if (y < 1200) {
//                String message = "year " + String.valueOf(y) + " is incorrect";
//                throw new HttpClientErrorException(HttpStatus.BAD_REQUEST, message);
//
//            }
//            //return new Greeting(y);
//            //logging the input
//            logger.info("Okay!");
//            boolean flag = hashMapa.greetingHashMap.containsKey(String.valueOf(y)); //returns true if map contains the key
//            if (flag) {
//                Greeting obj = hashMapa.greetingHashMap.get(String.valueOf(y));//returns object value which is defined by our key
//                logger.info("In a hash map");//cache placement reply
//                System.out.println("Cached!"); //shows that info was successfully placed
//                return obj;
//            }
//            hashMapa.greetingHashMap.put(String.valueOf(y), new Greeting(y)); //placing the data into the cache
//            return new Greeting(y);
//        } catch (NumberFormatException nfe) { //wasnt put in the cache error message with error 500
//            logger.error("Error occured");
//            String s = "error!";
//            throw new HttpServerErrorException(HttpStatus.INTERNAL_SERVER_ERROR, s);
//        }
//
//
//    }
//    @PostMapping(path = "/greetings", consumes = "application/json", produces = "application/json")
//    public ResponseEntity<Object> postCalendars(@RequestBody List<Leap> leap){
//        List<Greeting> greeting =
//    }
//}