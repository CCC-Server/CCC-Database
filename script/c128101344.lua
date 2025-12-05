local s,id=GetID()
function s.initial_effect(c)

	--------------------------------
	-- ① 카드 발동: 선언 → 확인 → 서치 or 특소
	--------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.tg1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)

	--------------------------------
	-- ② 묘지에서: 상대 NS/SS → 랭크업 + 이 카드 소재화
	--------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.con2)
	e2:SetTarget(s.tg2)
	e2:SetOperation(s.op2)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end


-----------------------------------------------------
-- ① EFFECT : Declare → Reveal → Search or Special Summon
-----------------------------------------------------
local type_map={
	[0]=TYPE_MONSTER,
	[1]=TYPE_SPELL,
	[2]=TYPE_TRAP
}

function s.thfilter(c,e,tp)
	return c:IsSetCard(0xc47) and c:IsMonster() and
		(c:IsAbleToHand() or c:IsCanBeSpecialSummoned(e,0,tp,false,false))
end

function s.tg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>0
			and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
end

function s.op1(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)==0 then return end

	-- Declare
	Duel.Hint(HINT_SELECTMSG,tp,569)
	local ann=Duel.AnnounceType(tp)
	local t=type_map[ann]

	-- Reveal opponent top card
	Duel.ConfirmDecktop(1-tp,1)
	local tc=Duel.GetDecktopGroup(1-tp,1):GetFirst()
	if not tc then return end

	local match = tc:IsType(t)

	-- Search Stellaron Hunter Monster
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g==0 then return end
	local sc=g:GetFirst()

	-- If match → allow Special Summon
	if match and sc:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.SelectYesNo(tp,aux.Stringid(id,2)) then
		
		Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP)
	else
		Duel.SendtoHand(sc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sc)
	end
end



-----------------------------------------------------
-- ② EFFECT : GY Rank-up + Attach this card as material
-----------------------------------------------------

-- 상대 소환만 반응
function s.con2(e,tp,eg,ep,ev,re,r,rp)
	return eg:GetFirst():GetSummonPlayer() == 1-tp
end

function s.xyzfilter_low(c)
	return c:IsFaceup() and c:IsSetCard(0xc47) and c:IsType(TYPE_XYZ)
end

function s.xyzfilter_high(c,e,tp,mc)
	return c:IsSetCard(0xc47)
		and c:IsType(TYPE_XYZ)
		and c:GetRank()>mc:GetRank()
		and Duel.GetLocationCountFromEx(tp,tp,mc,c)>0
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
end

function s.tg2(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.xyzfilter_low(chkc) end
	if chk==0 then
		return Duel.IsExistingTarget(s.xyzfilter_low,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,s.xyzfilter_low,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.op2(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsFaceup() or not tc:IsRelateToEffect(e) then return end

	-- select higher Rank Stellaron Hunter Xyz
	local xc=Duel.SelectMatchingCard(tp,s.xyzfilter_high,tp,LOCATION_EXTRA,0,1,1,nil,e,tp,tc):GetFirst()
	if not xc then return end

	Duel.BreakEffect()

	if Duel.SpecialSummon(xc,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)>0 then
		-- use tc as material
		local mg=Group.FromCards(tc)
		xc:SetMaterial(mg)
		Duel.Overlay(xc,mg)
		xc:CompleteProcedure()

		-- attach this card from GY
		if c:IsRelateToEffect(e) then
			Duel.Overlay(xc,c)
		end
	end
end
