#----------Preparing the data----------#

#Join 12 months data tables.
jointDataTable <- rbind(tripdata_2022_05, tripdata_2022_06, tripdata_2022_07, tripdata_2022_08, tripdata_2022_09, tripdata_2022_10,
                        tripdata_2022_11, tripdata_2022_12, tripdata_2023_01, tripdata_2023_02, tripdata_2023_03, tripdata_2023_04)

#Recreation of the data.frame columns including only the one needed from the raw data sets and creating new ones needed for the analysis.
ride_ID       <- jointDataTable$ride_id
bike_type     <- jointDataTable$rideable_type
ride_Started  <- jointDataTable$started_at
ride_Ended    <- jointDataTable$ended_at
customer_Type <- jointDataTable$member_casual

#This new column calculate the total length of the ride, we can assume that anything above 60 min is probably a leisure ride.
trip_time <- difftime(jointDataTable$ended_at, jointDataTable$started_at, units = "mins") 

#This new column help analyzing trends by day of the week as they are not present in the original raw data.
week_day <- weekdays(jointDataTable$started_at) 

#Create new data frame using previously renamed and new columns.
trip_data_clean = data.frame(ride_ID, bike_type, ride_Started, ride_Ended, week_day, trip_time, customer_Type)

#----------Cleaning the data----------#

#Remove duplicate data by ride_ID, each ride_ID is unique.
trip_data_clean[!duplicated(trip_data_clean$ride_ID), ]

#Filter out useless and inaccurate data including outliers to improve precision.
trip_data_clean = dplyr::filter(trip_data_clean, trip_time >= 4, trip_time <= 240)

#Create two separate tables for members and casuals this can help outlining trends per category.
casual_df  = dplyr::filter(trip_data_clean, customer_Type == "casual")
members_df = dplyr::filter(trip_data_clean, customer_Type == "member")

#Convert date data to double data for better calculations(personal preference).
casual_df$trip_time  = as.double(casual_df$trip_time)
members_df$trip_time = as.double(members_df$trip_time)

#----------Analyze the data----------#


#Summary of the analysis made on the observed data.
rides_summary <- 
  trip_data_clean %>%
  group_by(customer_Type) %>%
  summarise(average_trip_time=mean(trip_time),
            total_customer_type=sum(customer_Type == customer_Type),
            shorter_than_average=sum(trip_time < average_trip_time),
            longer_than_average=sum(trip_time > average_trip_time),
            total_long_trips = sum(trip_time >= 60))
  

#Analysis of trends by day of the week.
weekly_df = data.frame(trip_data$week_day, trip_data$customer_Type)

ride_per_weekday <-
  weekly_df %>%
  group_by(week_day) %>%
  summarize( total_rides=sum(customer_Type == customer_Type),
             casual_rides = sum(customer_Type == "casual"),
             member_rides = sum(customer_Type == "member"))

casual_weekly_rides <-
  weekly_df %>%
  group_by(week_day) %>%
  summarize(total_rides=sum(customer_Type == "casual"))

members_weekly_rides <-
  weekly_df %>%
  group_by(week_day) %>%
  summarize(total_rides=sum(customer_Type == "member"))

#Arrange the week_days data frame by casual/member user to facilitate analysis.
ride_per_weekday%>%
  arrange(ride_per_weekday$casual_rides)

ride_per_weekday%>%
  arrange(ride_per_weekday$member_rides)

#Creation and small analysis of rides by month.
monthly_df = data.frame(trip_data$ride_Started, trip_data$customer_Type)
monthly_df = separate(monthly_df, trip_data$ride_Started, into = c("trip_Date", "start_Time"), sep = ' ')
monthly_df = subset(monthly_df, select = -start_Time)
monthly_df = separate(monthly_df, trip_Date, into = c("year", "month"), sep = '-')
monthly_df = subset(monthly_df, select = -year)
monthly_df = separate(monthly_df, trip_Date, into = c("month", "day"), sep = '-')
monthly_df = subset(monthly_df, select = -day)

ride_by_month <-
  monthly_df %>%
  group_by(month) %>%
  summarize(num_of_rides=sum(customer_Type == customer_Type),
            casual_rides = sum(customer_Type == "casual"),
            member_rides = sum(customer_Type == "member"))

print(rides_summary)
print(ride_per_weekday)
print(ride_by_month)

#----------Data viz----------#

#Remove scientific notation as is not needed.
options(scipen = 999)

#Number of rides per day of the week.
ggplot(data = weekly_df) +
  geom_bar(mapping = aes(x = week_day, fill = week_day)) + 
  facet_wrap(~customer_Type)+
  labs(title = "Rides per day of the week.", subtitle = "Casual vs Members",
       caption = "Data collected by Motivate International Inc.") + 
  theme(axis.text.x = element_text(angle = 45))

#Casual weekly rides.
ggplot(data = casual_weekly_rides, aes(x = reorder(week_day, -total_rides) , y = total_rides, fill = week_day)) +  
  geom_bar(stat = "identity") + 
  labs(title = "Rides per day of the week.", subtitle = "Casual rides",
       caption = "Data collected by Motivate International Inc.",
       x = "Day of the week", y = "Ride count", fill = "Day")

#Members weekly rides.
ggplot(data = members_weekly_rides, aes(x = reorder(week_day, -total_rides) , y = total_rides, fill = week_day)) +  
  geom_bar(stat = "identity") + 
  labs(title = "Rides per day of the week.", subtitle = "Members rides",
       caption = "Data collected by Motivate International Inc.",
       x = "Day of the week", y = "Ride count", fill = "Day")
  
#Number of rides per month.
ggplot(data = monthly_df) +
  geom_bar(mapping = aes(x = month, fill = month)) + 
  facet_wrap(~customer_Type)+
  labs(title = "Rides per month.", subtitle = "Casual vs Month.",
       caption = "Data collected by Motivate International Inc.",
         x = "Month", y = "Ride count", fill = "Month")

  