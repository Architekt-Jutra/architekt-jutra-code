package calculator;

import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

class FeeCalculatorTest {

    // ❌ Mocking pure functions in a transformation test
    DiscountPolicy discountMock = mock(DiscountPolicy.class);
    SurchargePolicy surchargeMock = mock(SurchargePolicy.class);
    FeeCalculator sut = new FeeCalculator(discountMock, surchargeMock);

    @Test
    void should_calculate_fee_with_discount() {
        var products = List.of(
            new Product("p1", new BigDecimal("100.00"), 2, false, false),
            new Product("p2", new BigDecimal("50.00"), 1, false, false)
        );
        var context = new PricingContext(true, false);

        // ❌ Stubbing a pure function — why not just run it?
        when(discountMock.calculateDiscount(products, context))
            .thenReturn(new BigDecimal("12.50"));
        when(surchargeMock.calculateSurcharge(products, context))
            .thenReturn(BigDecimal.ZERO);

        var result = sut.calculate(products, context);

        assertThat(result.total()).isEqualByComparingTo("237.50");

        // ❌ Verifying interaction with a pure function — implementation leak
        verify(discountMock).calculateDiscount(products, context);
        verify(surchargeMock).calculateSurcharge(products, context);
    }

    @Test
    void should_calculate_fee_with_surcharge() {
        var products = List.of(
            new Product("p1", new BigDecimal("80.00"), 1, true, false)
        );
        var context = new PricingContext(false, true);

        when(discountMock.calculateDiscount(products, context))
            .thenReturn(BigDecimal.ZERO);
        // ❌ Hardcoded surcharge value — test doesn't verify surcharge logic
        when(surchargeMock.calculateSurcharge(products, context))
            .thenReturn(new BigDecimal("21.99"));

        var result = sut.calculate(products, context);

        assertThat(result.total()).isEqualByComparingTo("101.99");
        verify(surchargeMock).calculateSurcharge(products, context);
    }

    @Test
    void should_apply_both_discount_and_surcharge() {
        var products = List.of(
            new Product("p1", new BigDecimal("200.00"), 1, true, true)
        );
        var context = new PricingContext(true, true);

        when(discountMock.calculateDiscount(any(), any()))
            .thenReturn(new BigDecimal("10.00"));
        when(surchargeMock.calculateSurcharge(any(), any()))
            .thenReturn(new BigDecimal("64.99"));

        var result = sut.calculate(products, context);

        assertThat(result.baseAmount()).isEqualByComparingTo("200.00");
        assertThat(result.discount()).isEqualByComparingTo("10.00");
        assertThat(result.surcharge()).isEqualByComparingTo("64.99");
        assertThat(result.total()).isEqualByComparingTo("254.99");

        // ❌ Verifying call count on pure functions
        verify(discountMock, times(1)).calculateDiscount(any(), any());
        verify(surchargeMock, times(1)).calculateSurcharge(any(), any());
        verifyNoMoreInteractions(discountMock, surchargeMock);
    }
}
