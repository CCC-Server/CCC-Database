--Revelation of Ashening (가칭)
--scripted by 유희왕 덱 제작기

local s,id=GetID()
function s.initial_effect(c)
	-------------------------------------
	-- ① 이 카드의 발동: 덱에서 "회멸의 도시 옵시딤"을 필드존에 놓음
	-------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-------------------------------------
	-- ② 메인페이즈 중 서치 (1턴 1회)
	-------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(function() return Duel.IsMainPhase() end)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	-------------------------------------
	-- ③ 필드/묘지에서 "회멸의 도시 옵시딤"으로 취급
	-------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetCode(EFFECT_ADD_CODE)
	e3:SetRange(LOCATION_SZONE+LOCATION_GRAVE)
	e3:SetValue(CARD_OBSIDIM_ASHENED_CITY)
	c:RegisterEffect(e3)
end

------------------------------------------------------
-- ① 발동 시: 옵시딤을 필드존에 직접 세트
------------------------------------------------------
function s.obsfilter(c)
	return c:IsCode(CARD_OBSIDIM_ASHENED_CITY) and c:IsType(TYPE_FIELD) and not c:IsForbidden()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(s.obsfilter,tp,LOCATION_DECK,0,1,nil) then
		local g=Duel.SelectMatchingCard(tp,s.obsfilter,tp,LOCATION_DECK,0,1,1,nil)
		local tc=g:GetFirst()
		if not tc then return end
		local fc=Duel.GetFieldCard(tp,LOCATION_FZONE,0)
		if fc then
			Duel.SendtoGrave(fc,REASON_RULE)
			Duel.BreakEffect()
		end
		-- 필드 마법으로 이동
		if tc:IsType(TYPE_FIELD) and not tc:IsForbidden() then
			Duel.MoveToField(tc,tp,tp,LOCATION_FZONE,POS_FACEUP,true)
		else
			Debug.Message("선택된 카드가 필드 마법이 아니거나 금지된 카드입니다.")
		end
	end
end

------------------------------------------------------
-- ② 서치: 회멸 카드군 또는 베이도스
------------------------------------------------------
function s.thfilter(c)
	return (c:IsSetCard(SET_ASHENED) or c:IsCode(CARD_VEIDOS_ERUPTION_DRAGON))
		and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	else
		Debug.Message("서치 가능한 카드가 덱에 존재하지 않습니다.")
	end
end
