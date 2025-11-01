--암군의 융합결계 (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--① 패/필드의 몬스터를 융합 소재로 사용하여 레벨 8 이상의 융합 몬스터 융합 소환
	-- matfilter를 넣지 말아야 기본(패/필드) 재료를 사용합니다.
	local params={
		handler=c,
		fusfilter=s.fusfilter,
		-- matfilter= (지우기) ← 이 줄 때문에 발동 불가였음
		stage2=s.stage2
	}
	local e1=Fusion.CreateSummonEff(params)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E|TIMING_MAIN_END)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH) -- ① 발동 1턴 1번
	c:RegisterEffect(e1)

	--② 묘지로 보내졌을 경우: 자신 세트
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

-----------------------------------------------------------
--① 융합 조건: 레벨 8 이상의 융합 몬스터
-----------------------------------------------------------
function s.fusfilter(c)
	return c:IsType(TYPE_FUSION) and c:IsLevelAbove(8)
end
-----------------------------------------------------------
--② 묘지로 보내졌을 경우: 자신 세트
-----------------------------------------------------------
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsSSetable() then
		Duel.SSet(tp,c)
	end
end
