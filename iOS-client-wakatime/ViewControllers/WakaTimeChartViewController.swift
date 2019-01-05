//
//  WakaTimeChartViewController.swift
//  iOS-client-wakatime
//
//  Created by Liubov Fedorchuk on 23.01.2018.
//  Copyright © 2018 Liubov Fedorchuk. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper
import Charts

class WakaTimeChartViewController: UIViewController {
    
    lazy var dateManager = DateManager()
    lazy var chartFill = ChartFill()
    let statisticController = StatisticController()
    let summaryController = SummaryController()
    let alertSetUp = AlertSetUp()
    var isAuthenticated = false
    
    let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    
    @IBOutlet weak var todayChangesOfWorkingProgress: UILabel!
    @IBOutlet weak var todayWorkingProgressInPercent: UILabel!
    @IBOutlet weak var todayWorkingTimeLabel: UILabel!
    @IBOutlet weak var dailyAverageTimeLabel: UILabel!
    @IBOutlet weak var timeOfCodingLast7DaysLabel: UILabel!
    @IBOutlet weak var codingWithTimeLabel: UILabel!
    @IBOutlet weak var editorPieChartView: PieChartView!
    @IBOutlet weak var languagePieChartView: PieChartView!
    @IBOutlet weak var operatingSystemPieChartView: PieChartView!
    @IBOutlet weak var codingActivityCombinedChartView: CombinedChartView!
    @IBOutlet weak var codingDailyAverageHalfPieChartView: PieChartView!
    @IBOutlet weak var codingActivityCurrentlyHorizontalBarChartView: HorizontalBarChartView!
    @IBOutlet weak var weeklyBreakdownOverActivityHorizontalBarChartView: HorizontalBarChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !Connectivity.isConnectedToInternet {
            let alert = alertSetUp.showAlert(alertTitle: "No Internet Conection", alertMessage: "Turn on cellural data or use Wi-Fi to access data.")
            self.present(alert, animated: true, completion: nil)
        } else {
            let hasLogin = UserDefaults.standard.bool(forKey: "hasUserSecretAPIkey")
            if (!hasLogin) {
                self.performSegue(withIdentifier: "showWakaTimeLoginView", sender: self)
            } else {
                getStatisticForLast7Days()
                getSummaryForLast7Days()
                getDailyProgressForDailyCodingAvarageChart()
                chartFill.combinedChartFill(combinedChartView: codingActivityCombinedChartView)
                chartFill.horizontalBarChartFill(horizontalBarChartView: weeklyBreakdownOverActivityHorizontalBarChartView)
                fillLabelWithDailyWorkingTime()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewDidAppear(_ animated: Bool) {
        if !Connectivity.isConnectedToInternet {
            let alert = alertSetUp.showAlert(alertTitle: "No Internet Conection", alertMessage: "Turn on cellural data or use Wi-Fi to access data.")
            self.present(alert, animated: true, completion: nil)
        } else {
            let hasLogin = UserDefaults.standard.bool(forKey: "hasUserSecretAPIkey")
            if (!hasLogin) {
                self.performSegue(withIdentifier: "showWakaTimeLoginView", sender: self)
            } else {
                getStatisticForLast7Days()
                getSummaryForLast7Days()
                getDailyProgressForDailyCodingAvarageChart()
                chartFill.combinedChartFill(combinedChartView: codingActivityCombinedChartView)
                fillLabelWithDailyWorkingTime()
            }
        }
    }
    
    @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
        isAuthenticated = true
    }
    
    @IBAction func logoutWakaTimeButtonTapped(_ sender: Any) {
        self.logoutUserFromWakaTime()
    }
    
    func logoutUserFromWakaTime() {
        UserDefaults.standard.set(false, forKey: "hasUserSecretAPIkey")
        self.performSegue(withIdentifier: "showWakaTimeLoginView", sender: self)
        let keychainManager = KeychainManager()
        keychainManager.deleteUserSecretAPIkeyFromKeychain()  
    }
    
    func getStatisticForLast7Days() {
        statisticController.getUserStatisticsForGivenTimeRange(completionHandler: { statistic, status in
            if (statistic != nil && status == 200) {
                self.chartFill.pieChartFill(pieChartView: self.languagePieChartView,
                                  itemsList: (statistic?.usedLanguages)!)
                self.chartFill.pieChartFill(pieChartView: self.editorPieChartView,
                                    itemsList: (statistic?.usedEditors)!)
                self.chartFill.pieChartFill(pieChartView: self.operatingSystemPieChartView,
                                  itemsList: (statistic?.usedOperatingSystems)!)
                self.dailyAverageTimeLabel.text = statistic?.humanReadableDailyAverage!
            } else {
                guard status != nil else {
                    log.error("Unexpected error without status code.")
                    let alert = self.alertSetUp.showAlert(alertTitle: "Unexpected error",
                                              alertMessage: "Please, try again later.")
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                self.alertSetUp.showAlertAccordingToStatusCode(fromController: self, statusCode: status!)
            }
        })
    }
    
    private func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60)
    }
    
    func getSummaryForLast7Days() {
        let start = dateManager.getStartDayAsString()
        let end = dateManager.getCurrentDateAsString()
        
        summaryController.getUserSummaryForGivenTimeRange(startDate: start,
                                                          endDate: end,
                                                          completionHandler: { summary, status in
            if (summary != nil && status == 200) {
                var totalWorkingSecondsForLast7Days = 0
                for summaryItem in summary! {
                    totalWorkingSecondsForLast7Days += summaryItem.grandTotalTimeOfCodingInSeconds!
                }
                let totalWorkingHoursForLast7Days = self.secondsToHoursMinutesSeconds(seconds: totalWorkingSecondsForLast7Days).0
                let totalWorkingMinutesForLast7Days = self.secondsToHoursMinutesSeconds(seconds: totalWorkingSecondsForLast7Days).1
                self.timeOfCodingLast7DaysLabel.text = "\(totalWorkingHoursForLast7Days) hrs \(totalWorkingMinutesForLast7Days) mins in the Last 7 Days"
                self.codingWithTimeLabel.text = "Coding\n\(totalWorkingHoursForLast7Days)h \(totalWorkingMinutesForLast7Days)m"
            } else {
                guard status != nil else {
                    let alert = self.alertSetUp.showAlert(alertTitle: "Unexpected error", alertMessage: "Please, try again later.")
                    self.present(alert, animated: true, completion: nil)
                    log.error("Unexpected error without status code.")
                    return
                }
                
                self.alertSetUp.showAlertAccordingToStatusCode(fromController: self, statusCode: status!)
            }
        })
    }
    
    func fillLabelWithDailyWorkingTime() {
        let currentDate = dateManager.getCurrentDateAsString()
        
        summaryController.getUserSummaryForGivenTimeRange(startDate: currentDate,
                                                          endDate: currentDate,
                                                          completionHandler: { summary, status in
            if (summary != nil && status == 200) {
                for summaryItem in summary! {
                    guard summaryItem.grandTotalTimeOfCodindAsText != nil else {
                        self.todayWorkingTimeLabel.text = "0 secs"
                        return
                    }
                    self.todayWorkingTimeLabel.text = summaryItem.grandTotalTimeOfCodindAsText!
                }
            } else {
                    guard status != nil else {
                        let alert = self.alertSetUp.showAlert(alertTitle: "Unexpected error", alertMessage: "Please, try again later.")
                        self.present(alert, animated: true, completion: nil)
                        log.error("Unexpected error without status code.")
                        return
                    }
                self.alertSetUp.showAlertAccordingToStatusCode(fromController: self, statusCode: status!)
            }
        })
    }
    
    func getDailyProgressForDailyCodingAvarageChart() {
        let date = dateManager.getCurrentDateAsString()
        
        statisticController.getUserStatisticsForGivenTimeRange(completionHandler: { statistic, statusForStatistic in
            self.summaryController.getUserSummaryForGivenTimeRange(startDate: date,
                                                                     endDate: date,
                                                                     completionHandler:{ summary,
                                                                        statusForSummary in
                if ((statistic != nil && statusForStatistic == 200) || (summary != nil && statusForSummary == 200)) {

                    var dailyProgressListInPercent = [Double]()
                    for summaryItem in summary! {
                        let dailyAverageWorkingTimeInSeconds = (statistic?.dailyAverageWorkingTime!)!
                        let currentWorkingTimeInSecodns = summaryItem.grandTotalTimeOfCodingInSeconds!
                        let progressTime = currentWorkingTimeInSecodns * 100
                        if (dailyAverageWorkingTimeInSeconds == 0) {
                            self.todayWorkingProgressInPercent.text = "0.0%"
                            self.todayChangesOfWorkingProgress.text = "No Change"
                        } else {
                            let progressWorkingTimeInPercent: Double = Double(progressTime /
                                dailyAverageWorkingTimeInSeconds).rounded(toPlaces: 1)
                            dailyProgressListInPercent.append(progressWorkingTimeInPercent)
                            if (progressWorkingTimeInPercent > 100.0) {
                                let increase = progressWorkingTimeInPercent - 100.0
                                let progressWorkingTimeInPercentForDisplaying = progressWorkingTimeInPercent - increase
                                self.todayWorkingProgressInPercent.text = "\(progressWorkingTimeInPercentForDisplaying.rounded(toPlaces: 1))"
                                self.todayChangesOfWorkingProgress.text = "\(increase.rounded(toPlaces: 1))% Increase"
                            } else {
                                let decrease = 100.0 - progressWorkingTimeInPercent
                                dailyProgressListInPercent.append(decrease)
                                self.todayWorkingProgressInPercent.text = "\(progressWorkingTimeInPercent)%"
                                self.todayChangesOfWorkingProgress.text = "\(decrease.rounded(toPlaces: 1)) % Decrease"
                            }
                        }
                    }
                    self.chartFill.halfPieChartFill(halfPieChartView: self.codingDailyAverageHalfPieChartView,
                                              itemsList: dailyProgressListInPercent)
                } else {
                    guard statusForSummary != nil, statusForStatistic != nil else {
                        let alert = self.alertSetUp.showAlert(alertTitle: "Unexpected error",
                                                alertMessage: "Please, try again later.")
                        self.present(alert, animated: true, completion: nil)
                        log.error("Unexpected error without status code.")
                        return
                    }
                        
                    self.alertSetUp.showAlertAccordingToStatusCode(fromController: self, statusCode: statusForSummary!)
                    log.error("Unexpected error with statistic request with status code: \(statusForSummary!)")
                }
            })
        })
    }
}

extension WakaTimeChartViewController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return months[Int(value) % months.count]
    }
}
