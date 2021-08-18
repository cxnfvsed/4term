package com.example.demo.controller;

import java.util.LinkedList;
import java.util.List;

public class AverageValues {
   private List<Greeting> GreetingAnswerList = new LinkedList<>();
   private double numAverage;

   public void CalcAverage(List<Greeting> GreetingList){
       numAverage = GreetingList.stream().mapToInt(Greeting::getYear).average().getAsDouble(); //average of stream
   }

   public AverageValues(){}

   public List<Greeting> getGreetingAnswerList(){
       return GreetingAnswerList;
   }

   public void setGreetingAnswerList(List<Greeting> greetingAnswerList){
       GreetingAnswerList=greetingAnswerList;
   }

   public double getNumAverage(){
       return numAverage;
   }

   public void setNumAverage(double numAverage){
       this.numAverage=numAverage;
   }

   public AverageValues(double numAverage){
       this.numAverage = numAverage;
   }


}

