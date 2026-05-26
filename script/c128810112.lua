--드래고니아-아홉 꼬리 블로나
local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon
Synchro.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0xc05), 1, 1, Synchro.NonTuner(Card.IsSetCard, 0xc05), 1, 99)
	c:EnableReviveLimit()
	-- ①: 레벨 변경 (1턴에 1번)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.lvtg)
	e1:SetOperation(s.lvop)
	c:RegisterEffect(e1)
	-- ②: 파괴 대체 (1턴에 1번)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.reptg)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc05}

-- ① 레벨 변경 타겟
function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsFaceup() end
end
-- ① 레벨 변경 처리
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	-- 4~9 중 선택
	local lv=Duel.AnnounceLevel(tp,4,9,c:GetLevel())
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_LEVEL)
	e1:SetValue(lv)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end

-- ② 파괴 대체 필터
function s.repfilter(c)
	return c:IsSetCard(0xc05) and c:IsType(TYPE_MONSTER) and c:IsAbleToRemove()
end
-- ② 파괴 대체 타겟
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return not c:IsReason(REASON_REPLACE)
			and c:IsReason(REASON_EFFECT+REASON_BATTLE)
			and Duel.IsExistingMatchingCard(s.repfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	if Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,s.repfilter,tp,LOCATION_GRAVE,0,1,1,nil)
		e:SetLabelObject(g:GetFirst())
		return true
	else
		return false
	end
end
-- ② 파괴 대체 처리
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc then
		Duel.Remove(tc,POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
	end
end
