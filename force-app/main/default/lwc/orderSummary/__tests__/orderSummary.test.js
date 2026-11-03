import { createElement } from "lwc";
import OrderSummary from "c/orderSummary";

describe("c-order-summary", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders default metric values when summaryData is null", () => {
    const element = createElement("c-order-summary", {
      is: OrderSummary
    });
    document.body.appendChild(element);

    const metricValues = element.shadowRoot.querySelectorAll(".metric-value");
    expect(metricValues.length).toBeGreaterThan(0);
    expect(metricValues[0].textContent).toBe("0");
  });

  it("renders provided summaryData values", async () => {
    const element = createElement("c-order-summary", {
      is: OrderSummary
    });
    element.summaryData = {
      todaysOrderCount: 15,
      pendingApprovalCount: 2,
      preparingOrderCount: 4,
      servedOrderCount: 9,
      todaysSales: 450.5,
      availableTablesCount: 8,
      occupiedTablesCount: 4,
      cleaningTablesCount: 2
    };
    document.body.appendChild(element);

    await Promise.resolve();

    const metricValues = element.shadowRoot.querySelectorAll(".metric-value");
    expect(metricValues[0].textContent).toBe("15");
    expect(metricValues[1].textContent).toBe("2");
    expect(metricValues[2].textContent).toBe("4");
  });
});
