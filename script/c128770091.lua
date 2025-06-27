--싱크로 소재 지정: 튜너 + 튜너 이외의 "포츈 레이디" 몬스터 1장 이상
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x31),1,1,aux.FilterBoolFunction(Card.IsSetCard,0x31),1,99)
	--①: 레벨 x 400 공격/수비력
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SET_BASE_ATTACK)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetRange(LOCATION_MZONE)
	e0:SetValue(s.atkval)
	c:RegisterEffect(e0)

	local e0b=e0:Clone()
	e0b:SetCode(EFFECT_SET_BASE_DEFENSE)
	c:RegisterEffect(e0b)

	--②: 싱크로 소환 성공시 덱에서 "포츈" 마함 1장 서치
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--③: "포츈 레이디"가 소환되었을 때, 패/묘지에서 특수 소환 + 레벨 증가
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2b)
end

--①: 공격력/수비력 설정
function s.atkval(e,c)
	return c:GetLevel()*400
end

--②: 싱크로 소환 성공시
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

local special_codes = {
	[68663748]  = true,  -- 타임 패시지
	[20057949]  = true,  -- 운명만곡
	[72885174]  = true,
	[91407982]  = true,  -- 포츈 퓨처
	[94662235]  = true,  -- 포츈 비전
}
function s.thfilter(c)
	local code=c:GetCode()
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
	   and code~=id
	   and c:IsSSetable()
	   and ( c:IsSetCard(0x31) or special_codes[code] )
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) 
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--=============================================================================
--=============================================================================
-- ③: “포츈 레이디”가 일반/특수 소환되었을 때, 패/묘지의 포츈 레이디 1장을 특수 소환하고
--	 그 몬스터의 레벨을 1~2 올릴지 묻는 부분
--=============================================================================

-- (A) 필드에 이미 깔려 있는 자기 자신(ec)을 제외하고,
--	 새로 소환된 '포츈 레이디'(SetCard 0x31)가 내 필드에 존재하는지 확인
function s.cfilter(c, tp, ec)
	return c:IsFaceup() and c:IsSetCard(0x31) and c:IsControler(tp) and c~=ec
end

function s.spcon(e, tp, eg, ep, ev, re, r, rp)
	-- eg:IsExists(filter, 1, extra_arg, ... ) 형태로 쓰면, 내부에서 filter(c, tp, ec) 호출
	return eg:IsExists(s.cfilter, 1, e:GetHandler(), tp, e:GetHandler())
end

-- (B) 패/묘지에서 특수 소환할 '포츈 레이디'를 선택하여 타겟 지정
function s.spfilter(c, e, tp)
	return c:IsSetCard(0x31) and c:IsCanBeSpecialSummoned(e, 0, tp, false, false)
end

function s.sptg(e, tp, eg, ep, ev, re, r, rp, chk, chkc)
   if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_HAND+LOCATION_GRAVE) and s.spfilter(chkc,e,tp) end
	if chk==0 then return eg:IsExists(s.cfilter,1,nil,tp)
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end

-- (C) 실제 특수 소환 수행 후, “변경 안 함 / +1 레벨 / +2 레벨” 중에서 선택지 띄우기
function s.spop(e, tp, eg, ep, ev, re, r, rp)
   local tc=Duel.GetFirstTarget()
	if tc and Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
		Duel.SpecialSummonComplete()
		-- 레벨을 올릴지 여부를 먼저 선택
		if tc:IsFaceup() and tc:IsLevelAbove(1) and tc:IsCanBeEffectTarget(e) and Duel.SelectYesNo(tp, aux.Stringid(id, 0)) then
			Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,1)) -- "레벨을 선택하세요"
			local lv=Duel.AnnounceLevel(tp,1,2)
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_LEVEL)
			e1:SetValue(lv)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
			tc:RegisterEffect(e1)
		end
	end
end

-- 일반/특수 소환된 포츈 레이디 체크용
function s.cfilter(c,tp)
	return c:IsSetCard(0x31) and c:IsControler(tp)
end

-- 패/묘지에서 특수 소환할 포츈 레이디 대상 필터
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x31) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
