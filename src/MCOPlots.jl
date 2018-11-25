module MCOPlots

    # ----------------------------------------------------------------------------------
    #   Imports
    # ----------------------------------------------------------------------------------
    using MonteCarloObservable; const MCO = MonteCarloObservable;
    using StatsBase
    using PyPlot

    import PyPlot: plot










    # ----------------------------------------------------------------------------------
    #   Plots
    # ----------------------------------------------------------------------------------
    """
        plot(obs::Observable{T}[; errors=true, digits=3])

    Plot the observable's time series.
    """
    function plot(obs::Observable{T}; errors=true, digits=3) where T
        ts = timeseries(obs)
        Xmean = mean(obs)
        err = error(obs)
        Xstd = std(ts)

        fig, ax = subplots(1,1)
        ax[:plot](ts, ".-")
        ax[:set_ylabel](name(obs))
        ax[:set_xlabel]("Monte Carlo time \$ t \$")
        # ax[:set_yticks]([])
        ax[:axhline](Xmean, color="black", label="\$ $(round.(Xmean, digits=digits)) \$ (mean)", linewidth=2.0)

        if errors
            ax[:axhline](Xmean+err, color="r", label="\$ \\pm $(round.(err, digits=digits)) \$ (σ error)", linewidth=2.0)
            ax[:axhline](Xmean-err, color="r", linewidth=2.0)

            ax[:axhline](Xmean+2*err, color="r", alpha=.3, label="\$ \\pm $(round.(2*err, digits=digits)) \$ (2σ error)", linewidth=2.0)
            ax[:axhline](Xmean-2*err, color="r", alpha=.3, linewidth=2.0)

            ax[:axhline](Xmean+Xstd, color="g", label="\$ \\pm $(round.(Xstd, digits=digits)) \$ (std)", linewidth=2.0)
            ax[:axhline](Xmean-Xstd, color="g", linewidth=2.0)
        end

        ax[:legend](frameon=true, loc="best")

        tight_layout()
        nothing
    end







    ################################################
    """
        hist(obs::Observable{T}[; errors=true, digits=3])

    Plot a histogram of the observable's time series.
    """
    function hist(obs::Observable{T}; errors=true, digits=3, customtitle="") where T
        ts = timeseries(obs)
        Xmean = mean(obs)
        err = error(obs)
        Xstd = std(ts)

        fig, ax = subplots(1,1)
        ax[:hist](ts, 50, color="gray", alpha=.5, density=1)
        ax[:set_ylabel]("Frequency")
        ax[:set_xlabel](name(obs))
        ax[:set_yticks]([])
        ax[:axvline](Xmean, color="black", label="\$ $(round.(Xmean, digits=digits)) \$ (mean)", linewidth=2.0)

        if errors
            ax[:axvline](Xmean+err, color="r", label="\$ \\pm $(round.(err, digits=digits)) \$ (σ error)", linewidth=2.0)
            ax[:axvline](Xmean-err, color="r", linewidth=2.0)

            ax[:axvline](Xmean+2*err, color="r", alpha=.3, label="\$ \\pm $(round.(2*err, digits=digits)) \$ (2σ error)", linewidth=2.0)
            ax[:axvline](Xmean-2*err, color="r", alpha=.3, linewidth=2.0)

            ax[:axvline](Xmean+Xstd, color="g", label="\$ \\pm $(round.(Xstd, digits=digits)) \$ (std)", linewidth=2.0)
            ax[:axvline](Xmean-Xstd, color="g", linewidth=2.0)
        end

        ax[:legend](frameon=true, loc="best")

        if customtitle != ""
            title(customtitle)
        end

        tight_layout()
        nothing
    end







    ################################################
    """
        corrplot(obs::Observable{T})

    Plot the autocorrelation function of the observable.
    """
    function corrplot(obs::Observable{T}; showtau=false) where T
        ts = timeseries(obs)

        fig, ax = subplots(1,1)
        ax[:plot](autocor(ts), "-", color="k", linewidth=2.0)
        ax[:set_xlabel]("Monte Carlo time \$ t \$")
        ax[:set_ylabel]("Autocorrelation of $(name(obs))")

        if showtau
            t = tau(obs)
            tfinder = tau(obs, MCO.Rplateaufinder(obs)[2])
            tsum = sum(StatsBase.autocor(ts))
            ax[:axvline](x=t, color="red", label="tau ≈ $(round(t,2))")
            ax[:axvline](x=tfinder, color="orange", label="tau (finder) ≈ $(round(tfinder,2))")
            ax[:axvline](x=tsum, color="green", label="tau (sum) ≈ $(round(tsum,2))")
            # @show sum(StatsBase.autocor(ts))
            # @show Rplateaufinder(obs)[2]
            # @show tau(obs)
            ax[:axhline](y=exp(-1), color="gray", alpha=.2, label="1/e")
            ax[:legend]()
        end

        tight_layout()
        nothing
    end







    ################################################
    """
        binningplot(obs::Observable{T}[; min_nbins=32])

    Creates a plot of the binning error coefficient `R` as a function of bin size.

    The coefficient `R` should (up to statistical fluctuations) show a plateau for larger bin sizes,
    indicating that the bin averages have become independent.
    For correlated data one has `R>≈1` and `sqrt(R)` quantifies how much one would have underestimated
    the one-sigma errorbar.

    See [`binning_error`](@ref).
    """
    function binningplot(obs::Observable{T}; min_nbins=50) where T
        ts = timeseries(obs)

        bss, R, means = MCO.R_function(ts, min_nbins=min_nbins)

        figure()
        plot(bss, R, "m.-", label="R")
        plot(bss, means, ".-", label="R means")
        ylabel("error coefficient")
        legend()
        xlabel("bin size")
        tight_layout();
        nothing
    end






    ################################################
    """
        errorplot(obs::Observable{T})

    Creates a plot of the statistical standard error as a function of bin size.

    The standard error should (up to statistical fluctuations) show a plateau for larger bin sizes,
    indicating that the bin averages have become independent.

    See [`binning_error`](@ref), [`error`](@ref).
    """
    function errorplot(obs::Observable; customtitle::String="")
        ts = timeseries(obs)

        bss, R, means = MCO.R_function(ts, min_nbins=50)
        rawerrors = [MCO.binning_error_from_R(ts, r) for r in R]
        meanerrors = [MCO.binning_error_from_R(ts, r) for r in means]

        figure()
        plot(bss, rawerrors, "m.-", label="raw")
        plot(bss, meanerrors, ".-", label="means")
        ylabel("error")
        legend()
        xlabel("bin size")
        if customtitle != ""
            title(customtitle)
        end
        tight_layout();
        nothing
    end










    # ----------------------------------------------------------------------------------
    #   Exports
    # ----------------------------------------------------------------------------------
    export plot, hist, binningplot, errorplot, corrplot

end























    # # --------------------------------------
    # #           Playground
    # # --------------------------------------
    # # using Plots instead of PyPlot

    # function plot_histogram_Plots(obs::Observable{T}; errors=true, digits=3) where T
    #     ts = timeseries(obs)
    #     Xmean = mean(obs)
    #     err = std(obs)
    #     Xstd = std(ts)

    #     histogram(ts, framestyle=:box, grid=false, normed=true, label="", color="lightgrey")
    #     # ax[:hist](ts, 50, color="gray", alpha=.5, normed=1)
    #     ylabel!("Frequency")
    #     xlabel!(name(obs))
    #     yticks!(Float64[])
    #     vline!([Xmean], color="black", linewidth=2.0, label="\$ $(round.(Xmean, digits=digits)) \$ (mean)")

    #     if errors
    #         vline!([Xmean+err, Xmean-err], color="red", linewidth=2.0, label="\$ \\pm $(round.(err, digits=digits)) \$ (σ error)")
    #         vline!([Xmean+2*err, Xmean-2*err], color="red", linewidth=2.0, label="\$ \\pm $(round.(2*err, digits=digits)) \$ (2σ error)", alpha=.3)
    #         vline!([Xmean+Xstd, Xmean-Xstd], color="green", linewidth=2.0, label="\$ \\pm $(round.(Xstd, digits=digits)) \$ (std)", alpha=.3)
    #     end
    #     nothing
    # end
