# Load necessary libraries
library(tidyverse)   
library(dplyr)       
library(caret)
library(rpart)       
library(rpart.plot)
library(randomForest)  
library(pROC)
library(MASS)        
library(ggplot2)
library(cluster)     

# Load the dataset
# Download cosmeticdata.csv per data/README.md and place it in the data/ folder
file_path <- "data/cosmeticdata.csv"
df <- read_csv(file_path)

# Data Cleaning and Preprocessing

# Convert date fields to datetime format
# This ensures proper handling of date-based analysis
date_columns <- c("InitialDateReported", "MostRecentDateReported", "DiscontinuedDate", 
                  "ChemicalCreatedAt", "ChemicalUpdatedAt", "ChemicalDateRemoved")
df <- df %>% 
  mutate(across(all_of(date_columns), ~as.Date(., format = "%m/%d/%Y")))

# Handle missing values
# Replace missing numeric values with the median of the column
# Replace missing character values with "Unknown"
df <- df %>% 
  mutate(across(where(is.numeric), ~replace_na(., median(., na.rm = TRUE)))) %>%
  mutate(across(where(is.character), ~replace_na(., "Unknown")))

# Convert DiscontinuedDate to a binary variable (1 for Discontinued, 0 for Not Discontinued)
df <- df %>%
  mutate(Discontinued = ifelse(!is.na(DiscontinuedDate), 1, 0)) %>%
  dplyr::select(-DiscontinuedDate)  # Remove the original DiscontinuedDate column

# Convert categorical variables to factors for modeling purposes
df <- df %>% mutate(across(where(is.character), as.factor))

# Aggregate Data at the Product Level
# Grouping by product-related fields to summarize relevant numerical data
df_aggregated <- df %>%
  group_by(CDPHId, ProductName, CompanyName, BrandName, PrimaryCategory, SubCategory) %>%
  summarise(
    ChemicalCount = max(ChemicalCount),
    Discontinued = max(Discontinued),
    .groups = 'drop'
  )

# Clustering of Brands Based on Chemical Usage

# Aggregate chemical usage per brand for clustering analysis
brand_chemical_usage <- df %>%
  group_by(BrandName, ChemicalName, PrimaryCategory) %>%
  summarise(TotalChemicalCount = sum(ChemicalCount), .groups = 'drop')

# Perform K-Means Clustering with 5 clusters
set.seed(123)
kmeans_result <- kmeans(brand_chemical_usage %>% dplyr::select(TotalChemicalCount), centers = 5)
brand_chemical_usage$Cluster <- kmeans_result$cluster

# Show only the top 20 brands by chemical usage
top_brands <- brand_chemical_usage %>%
  arrange(desc(TotalChemicalCount)) %>%
  head(20)

# Visualize the top 20 brands by chemical usage
ggplot(top_brands, aes(x = reorder(BrandName, -TotalChemicalCount), 
                       y = TotalChemicalCount, fill = factor(Cluster))) +
  geom_bar(stat = "identity", position = "dodge") +  
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10)) +  
  labs(title = "Top 20 Brand Clustering Based on Chemical Usage", 
       x = "Brand", y = "Total Chemical Count") +
  scale_fill_brewer(palette = "Dark2")

# Classification: Predicting Product Discontinuation

# Prepare data for classification modeling
model_data <- df_aggregated %>%
  dplyr::select(Discontinued, ChemicalCount, PrimaryCategory, SubCategory)

# Split the data into training (80 percent) and testing (20 percent) sets
set.seed(123)
train_index <- createDataPartition(model_data$Discontinued, p = 0.8, list = FALSE)
train_data <- model_data[train_index, ]
test_data <- model_data[-train_index, ]

# Logistic Regression Model

# Train logistic regression model
logit_model <- glm(Discontinued ~ ., data = train_data, family = binomial)
summary(logit_model)

# Make predictions using logistic regression
logit_pred <- predict(logit_model, newdata = test_data, type = "response")
logit_pred_class <- ifelse(logit_pred > 0.5, 1, 0)

# Evaluate model performance using a confusion matrix
confusionMatrix(factor(logit_pred_class), factor(test_data$Discontinued))

# Random Forest Model

# Identify categorical variables with high cardinality (more than 53 levels)
high_cardinality_vars <- names(which(sapply(train_data, function(x) is.factor(x) && nlevels(x) > 53)))

# One-hot encode high-cardinality variables
dummies <- dummyVars(~ ., data = df[, high_cardinality_vars, drop = FALSE]) 
train_encoded <- predict(dummies, newdata = train_data)
test_encoded <- predict(dummies, newdata = test_data)

# Combine encoded data with original data
train_data_encoded <- cbind(train_data[, !names(train_data) %in% high_cardinality_vars], train_encoded)
test_data_encoded <- cbind(test_data[, !names(test_data) %in% high_cardinality_vars], test_encoded)

# Ensure column consistency between train and test sets
names(train_data_encoded) <- make.names(names(train_data_encoded))
names(test_data_encoded) <- make.names(names(test_data_encoded))

# Train Random Forest model
rf_model <- randomForest(factor(Discontinued) ~ ., data = train_data_encoded, ntree = 100)
rf_pred <- predict(rf_model, newdata = test_data_encoded)

# Evaluate the model using a confusion matrix
confusionMatrix(rf_pred, factor(test_data$Discontinued))

# Feature Importance Analysis
importance(rf_model)
varImpPlot(rf_model)

# ROC Curve Comparison
roc_obj_logit <- roc(test_data$Discontinued, logit_pred)
roc_obj_rf <- roc(test_data$Discontinued, as.numeric(rf_pred))

# Plot ROC curves for both models
plot(roc_obj_logit, main = "ROC Curves")
lines(roc_obj_rf, col = "red")
legend("bottomright", legend = c("Logistic Regression", "Random Forest"), 
       col = c("black", "red"), lwd = 2)

# Discontinuation Analysis

# Analyze discontinuation rates by product category
primary_category_discontinuation <- df %>%
  group_by(PrimaryCategory) %>%
  summarise(DiscontinuationRate = mean(Discontinued, na.rm = TRUE)) %>%
  arrange(desc(DiscontinuationRate))

# Print discontinuation rates per category
print(primary_category_discontinuation)

# Print AUC scores for both models
cat("AUC for Logistic Regression:", auc(roc_obj_logit), "\n")
cat("AUC for Random Forest:", auc(roc_obj_rf), "\n")
