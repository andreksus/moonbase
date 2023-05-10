import { createSlice, createAsyncThunk } from '@reduxjs/toolkit'
import React from "react";
import axios from "axios";

export const appSlice = createSlice({
    name: 'app',
    initialState: {
        value: 0,
        modalComponent: 'device',
        modalActivePage: 0,
        modalName: "Log In",
        openModal: false,
        user: null,
        accountSettings: true,
        topLeftButton: null,
        backButton: null,
        closeButton: null,
        alertsPage : null,
        tempTrackedWallet: null,
        payment : null,
        searchAccountName : null,
        searchAccountAddress : null,
        searchAccounts : null,
        editCardId: null,
        subPeriod: 6,
        searchComplete: false,
        eth_price: {
            ETH: {USD: 1602.59, MATIC: 1737.92, ETH: 1, KLAY: 5974.79},
            KLAY: {USD: 0.2681, MATIC: 0.2909, ETH: 0.0001674, KLAY: 1},
            MATIC: {USD: 0.9215, MATIC: 1, ETH: 0.0005754, KLAY: 3.438},
        }
    },
    reducers: {
        SET_MODAL: (state, action) => {
            state.modalActivePage = action.payload.active_page;
            state.modalName = action.payload.modal_name;
            state.openModal = action.payload.modal_open;
            state.modalComponent = action.payload.component;
            state.topLeftButton = action.payload.top_left_button;
            state.backButton = action.payload.back_button;
            state.alertsPage = action.payload.alerts_page;
            state.editCardId = action.payload.edit_card_id;
            state.closeButton = action.payload.close_button;
        },
        SET_MODAL_ACTIVE_PAGE: (state, action) => {
            state.modalActivePage = action.payload;
        },
        SET_CURRENT_USER: (state, action) => {
            state.user = action.payload;
        },
        SET_ACCOUNT_SETTINGS: (state, action) => {
            state.accountSettings = action.payload;
        },
        SET_TRACKED_WALLET: (state, action) => {
            state.tempTrackedWallet = action.payload;
        },
        SET_CURRENT_PAYMENT: (state, action) => {
            state.payment = action.payload;
        },
        SET_SEARCH_ACCOUNT: (state, action) => {
            state.searchAccounts = action.payload.search_accounts;
        },
        SET_CHOSEN_ACCOUNT: (state, action) => {
            state.searchAccountName = action.payload.search_account_name;
            state.searchAccountAddress = action.payload.search_account_address;
        },
        SET_SUB_PERIOD: (state, action) => {
            state.subPeriod = action.payload.sub_period;
        },
        SET_SEARCH_COMPLETE: (state, action) => {
            state.searchComplete = action.payload.search_complete;
        },
        SET_ETH_PRICE: (state, action) => {
            state.eth_price = action.payload;
        },

    }
});

export const getUserAsync = createAsyncThunk("app/getUserAsync",
    async (id, thunkAPI) => {

        let localUser = JSON.parse(localStorage.getItem("user"))
        if (localUser) {
            thunkAPI.dispatch(SET_ETH_PRICE(localUser.eth_price));
            thunkAPI.dispatch(SET_CURRENT_USER(localUser.user));
            thunkAPI.dispatch(SET_CURRENT_PAYMENT(localUser.payment));
        }
            const user = await axios.get("/api/v1/user.json");
            thunkAPI.dispatch(SET_ETH_PRICE(user.data.eth_price));

            if ((user === null) || (user === undefined)) {
                return Promise.reject("user is not loaded");
            }

            thunkAPI.dispatch(SET_CURRENT_USER(user.data.user));
            thunkAPI.dispatch(SET_CURRENT_PAYMENT(user.data.payment));
            localStorage.setItem("user", JSON.stringify(user.data))
    });

// export const getETHAsync = createAsyncThunk("app/getETHAsync",
//     async (id, thunkAPI) => {
//         const user = await axios.get("/api/v1/user/ethereum_price.json");
//
//         thunkAPI.dispatch(SET_ETH_PRICE(user.data.eth_price));
//
//         if ((user === null) || (user === undefined)) {
//             return Promise.reject("eth is not loaded");
//         }
//
//     });

// Action creators are generated for each case reducer function
export const {
    SET_MODAL,
    SET_CURRENT_USER,
    SET_CURRENT_PAYMENT,
    SET_MODAL_ACTIVE_PAGE,
    SET_ACCOUNT_SETTINGS,
    SET_TRACKED_WALLET,
    SET_SEARCH_ACCOUNT,
    SET_CHOSEN_ACCOUNT,
    SET_SUB_PERIOD,
    SET_SEARCH_COMPLETE,
    SET_ETH_PRICE
} = appSlice.actions;

export const selectModalComponent = (state) => state.app.modalComponent;
export const selectModalName = (state) => state.app.modalName;
export const selectModalActivePage = (state) => state.app.modalActivePage;
export const selectOpenModal = (state) => state.app.openModal;
export const selectUser = (state) => state.app.user;
export const selectPayment = (state) => state.app.payment;
export const selectAccountSettings = (state) => state.app.accountSettings;
export const selectTopLeftButton = (state) => state.app.topLeftButton;
export const selectBackButton = (state) => state.app.backButton;
export const selectAlertsPage = (state) => state.app.alertsPage;
export const selectTrackedWallet = (state) => state.app.tempTrackedWallet;
export const selectSearchAccountName = (state) => state.app.searchAccountName;
export const selectSearchAccountAddress = (state) => state.app.searchAccountAddress;
export const selectSearchAccounts = (state) => state.app.searchAccounts;
export const selectCardId = (state) => state.app.editCardId;
export const selectCloseButton = (state) => state.app.closeButton;
export const selectSubPeriod = (state) => state.app.subPeriod;
export const selectSearchComplete = (state) => state.app.searchComplete;
export const selectETHPrice = (state) => state.app.eth_price;







export default appSlice.reducer;
