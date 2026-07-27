import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";

if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
export const auth = getAuth();

export function businessRef(businessId: string) {
  return db.collection("businesses").doc(businessId);
}

export function customersCol(businessId: string) {
  return businessRef(businessId).collection("customers");
}

export function transactionsCol(businessId: string) {
  return businessRef(businessId).collection("transactions");
}

export function otpsCol(businessId: string) {
  return businessRef(businessId).collection("otps");
}

export function statsDoc(businessId: string) {
  return businessRef(businessId).collection("stats").doc("summary");
}

export function privateGatewayDoc(businessId: string) {
  return businessRef(businessId).collection("private").doc("otpGateway");
}
